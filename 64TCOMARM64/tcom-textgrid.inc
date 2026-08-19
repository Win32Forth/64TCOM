/* tcom-textgrid.inc — pasted into TCOM GUI .m by MACHOARM64
 * 80x25 DOS-style text grid + host_fn[] for AT/CLS/EMIT/GET-CHAR/KEY?/KEY/timers/TYPE/DOT/TONE
 * Public domain.
 */
#include <sys/time.h>
#include <unistd.h>
#include <ctype.h>
#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdlib.h>
#include <fcntl.h>
#include <errno.h>

enum { TCOM_COLS = 80, TCOM_ROWS = 25, TCOM_KEYCAP = 64 };

typedef int64_t (*tcom_host_fn)(int64_t, int64_t);

static int tcom_gui_opened = 0;
static char tcom_app_name[256] = "64TCOM";
static uint8_t tcom_cells[TCOM_COLS * TCOM_ROWS];
static int tcom_cx = 0, tcom_cy = 0;
static int tcom_dirty = 0;
static int64_t tcom_keys[TCOM_KEYCAP];
static int tcom_kr = 0, tcom_kw = 0;
static struct timeval tcom_t0;
static NSWindow *tcom_window = nil;
static NSView *tcom_grid_view = nil;
static CGFloat tcom_cell_w = 9.0, tcom_cell_h = 16.0;
static struct timeval tcom_last_pump;
uint64_t tcom_dsp0 = 0;
uint8_t *tcom_data0 = 0;
static uint64_t tcom_dsp_min = ~(uint64_t)0;
static int tcom_dsp_reports = 0;

/* b = Forth DSP (X19) from KEY?/10TH-ELAPSED. Track growth (DSP descends). */
static int tcom_dsp_samples = 0;
uint8_t *tcom_dsp_floor = 0;
static void tcom_note_dsp(int64_t dsp_in) {
  if (dsp_in == 0) return;
  uint64_t dsp = (uint64_t)dsp_in;
  if (tcom_dsp0 == 0) {
    tcom_dsp0 = dsp;
    tcom_dsp_min = dsp;
    fprintf(stderr, "TCOM DSP baseline %llu\n", (unsigned long long)dsp);
    fflush(stderr);
    return;
  }
  tcom_dsp_samples++;
  int64_t used = (int64_t)(tcom_dsp0 - dsp);
  if (dsp < tcom_dsp_min) {
    tcom_dsp_min = dsp;
    /* Rare diagnostic — rising cell count means a Forth stack leak */
    if (tcom_dsp_reports < 8) {
      fprintf(stderr, "TCOM DSP NEW MIN used %lld cells\n",
              (long long)(used / 8));
      fflush(stderr);
    }
    tcom_dsp_reports++;
  }
}

static void tcom_grid_clear(void) {
  memset(tcom_cells, 32, sizeof tcom_cells);
  tcom_cx = tcom_cy = 0;
  tcom_dirty = 1;
}

static void tcom_key_push(int64_t c) {
  int n = (tcom_kw + 1) % TCOM_KEYCAP;
  if (n == tcom_kr) return; /* full */
  tcom_keys[tcom_kw] = c;
  tcom_kw = n;
}

static int64_t tcom_key_pop(void) {
  if (tcom_kr == tcom_kw) return -1;
  int64_t c = tcom_keys[tcom_kr];
  tcom_kr = (tcom_kr + 1) % TCOM_KEYCAP;
  return c;
}

static int64_t tcom_map_keycode(unsigned short kc, NSString *chars) {
  /* F-PC / classic TCOM arrow codes = scan + 128 */
  switch (kc) {
    case 123: return 203; /* left */
    case 124: return 205; /* right */
    case 125: return 208; /* down */
    case 126: return 200; /* up */
    case 53:  return 0x1B; /* escape */
    case 49:  return 0x20; /* space */
    default: break;
  }
  if (chars && [chars length] > 0) {
    unichar u = [chars characterAtIndex:0];
    if (u < 128) return (int64_t)u;
  }
  return -1;
}

@interface TcomGridView : NSView
@end
@implementation TcomGridView
- (BOOL)acceptsFirstResponder { return YES; }
- (BOOL)becomeFirstResponder { return YES; }
- (void)keyDown:(NSEvent *)event {
  int64_t c = tcom_map_keycode([event keyCode], [event charactersIgnoringModifiers]);
  if (c == 0x1B) {
    [NSApp terminate:nil];
    return;
  }
  if (c >= 0) tcom_key_push(c);
}
- (void)moveUp:(id)sender    { (void)sender; tcom_key_push(200); }
- (void)moveDown:(id)sender  { (void)sender; tcom_key_push(208); }
- (void)moveLeft:(id)sender  { (void)sender; tcom_key_push(203); }
- (void)moveRight:(id)sender { (void)sender; tcom_key_push(205); }
- (void)drawRect:(NSRect)dirty {
  (void)dirty;
  [[NSColor blackColor] setFill];
  NSRectFill([self bounds]);
  NSFont *font = [NSFont monospacedSystemFontOfSize:tcom_cell_h - 2 weight:NSFontWeightRegular];
  if (!font) font = [NSFont userFixedPitchFontOfSize:tcom_cell_h - 2];
  NSDictionary *attrs = @{
    NSFontAttributeName: font,
    NSForegroundColorAttributeName: [NSColor colorWithCalibratedRed:0.7 green:1.0 blue:0.7 alpha:1.0]
  };
  for (int y = 0; y < TCOM_ROWS; y++) {
    for (int x = 0; x < TCOM_COLS; x++) {
      uint8_t ch = tcom_cells[y * TCOM_COLS + x];
      NSString *s;
      if (ch == 219) s = @"\u2588";      /* full block */
      else if (ch == 0 || ch == 255) s = @" ";
      else s = [NSString stringWithFormat:@"%c", (ch >= 32 && ch < 127) ? (char)ch : '?'];
      CGFloat px = x * tcom_cell_w + 4.0;
      /* DOS (0,0) top-left → AppKit bottom-left */
      CGFloat py = (TCOM_ROWS - 1 - y) * tcom_cell_h + 4.0;
      [s drawAtPoint:NSMakePoint(px, py) withAttributes:attrs];
    }
  }
}
@end

@interface TcomAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate>
@end
@implementation TcomAppDelegate
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  (void)sender; return YES;
}
/* Forth pumps nextEvent itself (not [NSApp run]), so terminate: is deferred
 * and a closed window is then messaged → crash dialog. Exit here instead. */
- (void)windowWillClose:(NSNotification *)note {
  (void)note;
  tcom_gui_opened = 0;
  tcom_grid_view = nil;
  tcom_window = nil;
  _exit(0);
}
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  (void)sender;
  _exit(0);
  return NSTerminateNow;
}
@end

static void tcom_install_main_menu(NSApplication *app) {
  NSString *name = [NSString stringWithUTF8String:tcom_app_name];
  NSString *quit = [@"Quit " stringByAppendingString:name];
  if ([app mainMenu] != nil) {
    NSMenuItem *appItem = [[app mainMenu] itemAtIndex:0];
    NSMenu *appMenu = [appItem submenu];
    [appMenu setTitle:name];
    if ([appMenu numberOfItems] > 0) [[appMenu itemAtIndex:0] setTitle:quit];
    return;
  }
  NSMenu *menubar = [NSMenu new];
  NSMenuItem *appItem = [NSMenuItem new];
  [menubar addItem:appItem];
  NSMenu *appMenu = [[NSMenu alloc] initWithTitle:name];
  NSMenuItem *quitItem = [[NSMenuItem alloc]
    initWithTitle:quit action:@selector(terminate:) keyEquivalent:@"q"];
  [quitItem setTarget:app];
  [appMenu addItem:quitItem];
  [appItem setSubmenu:appMenu];
  [app setMainMenu:menubar];
}

/* Drain AppKit events. Throttled: KEY? spins without this would call
 * displayIfNeeded + autorelease millions of times/sec (looks like a leak). */
static void tcom_pump(void) {
  if (!tcom_gui_opened) return;
  struct timeval now;
  gettimeofday(&now, NULL);
  if (tcom_last_pump.tv_sec != 0) {
    int64_t us = (int64_t)(now.tv_sec - tcom_last_pump.tv_sec) * 1000000LL
               + (int64_t)(now.tv_usec - tcom_last_pump.tv_usec);
    if (us >= 0 && us < 8000) return; /* ~125 Hz max */
  }
  tcom_last_pump = now;
  @autoreleasepool {
    NSEvent *e;
    while ((e = [NSApp nextEventMatchingMask:NSEventMaskAny
                                   untilDate:[NSDate distantPast]
                                      inMode:NSDefaultRunLoopMode
                                     dequeue:YES])) {
      [NSApp sendEvent:e];
      if (!tcom_gui_opened) _exit(0);
    }
    if (tcom_dirty && tcom_grid_view) {
      [tcom_grid_view setNeedsDisplay:YES];
      tcom_dirty = 0;
    }
  }
}

/* Force a flush (CLS / slow path) */
static void tcom_pump_flush(void) {
  if (!tcom_gui_opened) return;
  tcom_last_pump.tv_sec = 0; /* bypass throttle */
  tcom_pump();
  if (tcom_window) [tcom_window displayIfNeeded];
}

static void tcom_put_xy(int x, int y, uint8_t c) {
  if (x < 0 || y < 0 || x >= TCOM_COLS || y >= TCOM_ROWS) return;
  tcom_cells[y * TCOM_COLS + x] = c;
  tcom_dirty = 1;
}

static void tcom_emit_char(int64_t c) {
  if (c == 10 || c == 13) {
    tcom_cx = 0;
    if (tcom_cy < TCOM_ROWS - 1) tcom_cy++;
    return;
  }
  if (c == 8) { /* backspace */
    if (tcom_cx > 0) tcom_cx--;
    tcom_put_xy(tcom_cx, tcom_cy, 32);
    return;
  }
  tcom_put_xy(tcom_cx, tcom_cy, (uint8_t)(c & 255));
  tcom_cx++;
  if (tcom_cx >= TCOM_COLS) {
    tcom_cx = 0;
    if (tcom_cy < TCOM_ROWS - 1) tcom_cy++;
  }
}

static int64_t tcom_host_window(int64_t a, int64_t b) {
  (void)a; (void)b;
  tcom_grid_clear();
  gettimeofday(&tcom_t0, NULL);
  NSApplication *app = [NSApplication sharedApplication];
  [app setActivationPolicy:NSApplicationActivationPolicyRegular];
  static TcomAppDelegate *delegate = nil;
  if (!delegate) { delegate = [TcomAppDelegate new]; [app setDelegate:delegate]; }
  tcom_install_main_menu(app);

  NSFont *font = [NSFont monospacedSystemFontOfSize:14.0 weight:NSFontWeightRegular];
  if (!font) font = [NSFont userFixedPitchFontOfSize:14.0];
  tcom_cell_h = [font ascender] - [font descender] + 2.0;
  tcom_cell_w = [@"M" sizeWithAttributes:@{NSFontAttributeName:font}].width;
  if (tcom_cell_w < 1.0) tcom_cell_w = 9.0;
  if (tcom_cell_h < 1.0) tcom_cell_h = 16.0;

  CGFloat w = TCOM_COLS * tcom_cell_w + 8.0;
  CGFloat h = TCOM_ROWS * tcom_cell_h + 8.0;
  NSRect frame = NSMakeRect(80, 60, w, h);
  NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                     NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable;
  tcom_window = [[NSWindow alloc] initWithContentRect:frame
    styleMask:style backing:NSBackingStoreBuffered defer:NO];
  [tcom_window setTitle:[NSString stringWithUTF8String:tcom_app_name]];
  [tcom_window setDelegate:delegate];
  TcomGridView *view = [[TcomGridView alloc] initWithFrame:NSMakeRect(0, 0, w, h)];
  [view setWantsLayer:YES];
  tcom_grid_view = view;
  [tcom_window setContentView:view];
  [tcom_window makeKeyAndOrderFront:nil];
  [tcom_window makeFirstResponder:view];
  [app activateIgnoringOtherApps:YES];
  [app finishLaunching];
  tcom_gui_opened = 1;
  tcom_dirty = 1;
  tcom_pump_flush();
  return 0;
}

static int64_t tcom_host_app_name(int64_t ca, int64_t u) {
  size_t n = (size_t)u; if (n > 255u) n = 255u;
  if (!ca || n == 0) strcpy(tcom_app_name, "64TCOM");
  else { memcpy(tcom_app_name, (const void *)(uintptr_t)ca, n); tcom_app_name[n] = 0; }
  NSApplication *app = [NSApplication sharedApplication];
  if ([app mainMenu] != nil) tcom_install_main_menu(app);
  if (tcom_window) [tcom_window setTitle:[NSString stringWithUTF8String:tcom_app_name]];
  return 0;
}

static int64_t tcom_host_at(int64_t x, int64_t y) {
  if (x < 0) x = 0;
  if (y < 0) y = 0;
  if (x >= TCOM_COLS) x = TCOM_COLS - 1;
  if (y >= TCOM_ROWS) y = TCOM_ROWS - 1;
  tcom_cx = (int)x;
  tcom_cy = (int)y;
  return 0;
}

static int64_t tcom_host_cls(int64_t a, int64_t b) {
  (void)a; (void)b;
  tcom_grid_clear();
  tcom_pump_flush();
  return 0;
}

static int64_t tcom_host_getchar(int64_t a, int64_t b) {
  (void)a; (void)b;
  if (tcom_cx < 0 || tcom_cy < 0 || tcom_cx >= TCOM_COLS || tcom_cy >= TCOM_ROWS)
    return 32;
  return (int64_t)tcom_cells[tcom_cy * TCOM_COLS + tcom_cx];
}

static int64_t tcom_host_emit(int64_t c, int64_t b) {
  (void)b;
  tcom_emit_char(c);
  return 0;
}

static int64_t tcom_host_keyq(int64_t a, int64_t b) {
  (void)a;
  tcom_note_dsp(b); /* b = Forth X19 DSP; logs only on NEW MIN */
  if (tcom_dsp_floor && (uint8_t *)(uintptr_t)b &&
      (uint8_t *)(uintptr_t)b < tcom_dsp_floor)
    _exit(0);
  tcom_pump();
  if (tcom_kr != tcom_kw) return -1;
  /* ~8 ms when idle: responsive keys, not a 1 kHz DSP spin */
  usleep(8000);
  return 0;
}

static int64_t tcom_host_key(int64_t a, int64_t b) {
  (void)a; (void)b;
  tcom_pump();
  {
    int64_t c = tcom_key_pop();
    if (c >= 0) return c;
  }
  /* Non-blocking: WAIT-DROP is KEY? IF KEY — never sleep here. */
  return 0;
}

static int64_t tcom_host_timer_reset(int64_t a, int64_t b) {
  (void)a; (void)b;
  gettimeofday(&tcom_t0, NULL);
  return 0;
}

static int64_t tcom_tenths_now(void) {
  struct timeval now;
  gettimeofday(&now, NULL);
  int64_t us = (int64_t)(now.tv_sec - tcom_t0.tv_sec) * 1000000LL
             + (int64_t)(now.tv_usec - tcom_t0.tv_usec);
  if (us < 0) us = 0;
  return us / 100000LL; /* tenths of a second */
}

static int64_t tcom_host_tenths_elapsed(int64_t a, int64_t b) {
  (void)a;
  tcom_note_dsp(b);
  tcom_pump();
  return tcom_tenths_now();
}

static int64_t tcom_host_tenths(int64_t n, int64_t b) {
  (void)b;
  if (n < 0) n = 0;
  /* Sleep without nested nextEvent — same stall as TONE-from-MOVEMENT. */
  {
    useconds_t us = (useconds_t)n * 100000u;
    if (us > 0) usleep(us);
  }
  return 0;
}

static int64_t tcom_host_type(int64_t ca, int64_t u) {
  if (!ca || u <= 0) return 0;
  const char *p = (const char *)(uintptr_t)ca;
  for (int64_t i = 0; i < u; i++) tcom_emit_char((unsigned char)p[i]);
  tcom_pump_flush();
  return 0;
}

static void tcom_wu32(uint8_t *p, int off, uint32_t v) {
  p[off] = (uint8_t)(v & 255);
  p[off + 1] = (uint8_t)((v >> 8) & 255);
  p[off + 2] = (uint8_t)((v >> 16) & 255);
  p[off + 3] = (uint8_t)((v >> 24) & 255);
}
static void tcom_wu16(uint8_t *p, int off, uint16_t v) {
  p[off] = (uint8_t)(v & 255);
  p[off + 1] = (uint8_t)((v >> 8) & 255);
}

/* Minimal mono 16-bit WAV sine (22.05 kHz). */
static NSData *tcom_sine_wav(double hz, double seconds) {
  const double sr = 22050.0;
  int n = (int)(sr * seconds);
  if (n < 1) n = 1;
  NSMutableData *d = [NSMutableData dataWithLength:(NSUInteger)(44 + n * 2)];
  if (!d) return nil;
  uint8_t *p = (uint8_t *)[d mutableBytes];
  memcpy(p, "RIFF", 4);
  tcom_wu32(p, 4, 36 + (uint32_t)(n * 2));
  memcpy(p + 8, "WAVEfmt ", 8);
  tcom_wu32(p, 16, 16);
  tcom_wu16(p, 20, 1);
  tcom_wu16(p, 22, 1);
  tcom_wu32(p, 24, (uint32_t)sr);
  tcom_wu32(p, 28, (uint32_t)(sr * 2));
  tcom_wu16(p, 32, 2);
  tcom_wu16(p, 34, 16);
  memcpy(p + 36, "data", 4);
  tcom_wu32(p, 40, (uint32_t)(n * 2));
  {
    double twopi = 2.0 * 3.141592653589793 * hz;
    double attack = seconds < 0.04 ? seconds / 4.0 : 0.01;
    double release = seconds < 0.06 ? seconds / 3.0 : 0.02;
    int16_t *s = (int16_t *)(p + 44);
    int i;
    for (i = 0; i < n; i++) {
      double t = (double)i / sr;
      double env = 1.0;
      double x;
      if (t < attack) env = t / attack;
      if (t > seconds - release) env = (seconds - t) / release;
      if (env < 0.0) env = 0.0;
      x = sin(twopi * t) * 0.35 * env * 32767.0;
      if (x > 32767.0) x = 32767.0;
      if (x < -32767.0) x = -32767.0;
      s[i] = (int16_t)x;
    }
  }
  return d;
}

/* TONE: freq = Hz, dur = tenths of a second (F-PC). Plays sine; beeps on failure. */
static int64_t tcom_host_tone(int64_t freq, int64_t dur) {
  double hz = (double)freq;
  double seconds;
  if (hz < 20.0) hz = 20.0;
  if (hz > 12000.0) hz = 12000.0;
  if (dur < 0) dur = 0;
  if (dur > 50) dur = 50; /* F-PC 50 umin */
  if (dur == 0) return 0;
  seconds = (double)dur / 10.0;
  {
    NSData *wav = tcom_sine_wav(hz, seconds);
    if (wav) {
      NSSound *snd = [[NSSound alloc] initWithData:wav];
      if (snd) [snd play];
      else NSBeep();
    } else {
      NSBeep();
    }
  }
  /* Block for duration like F-PC. Do NOT nest tcom_pump/nextEvent here —
     TONE is often called from the same thread that already pumps in KEY?/MAIN;
     nested nextEvent stalls the game loop after the first MUSIC note. */
  {
    useconds_t us = (useconds_t)(seconds * 1000000.0);
    if (us < 1000) us = 1000;
    usleep(us);
  }
  return 0;
}

static int64_t tcom_host_dot(int64_t n, int64_t b) {
  (void)b;
  char buf[32];
  int len = snprintf(buf, sizeof buf, "%lld", (long long)n);
  if (len < 0) return 0;
  for (int i = 0; i < len; i++) tcom_emit_char((unsigned char)buf[i]);
  return 0;
}

/* ( line, DSP ) — remaining stack already in memory at DSP. Caller then
   LDR-POST so TOS returns to X0. */
static int64_t tcom_host_stackhud(int64_t line_y, int64_t dsp_in) {
  char line[81];
  int64_t tos = 0, n1 = 0, n2 = 0, n3 = 0;
  int64_t depth = 0;
  int y, i, len;
  y = (int)line_y;
  if (y < 0) y = 0;
  if (y >= TCOM_ROWS) y = TCOM_ROWS - 1;
  if (tcom_dsp0 && dsp_in && (uint64_t)dsp_in <= tcom_dsp0)
    depth = (int64_t)((tcom_dsp0 - (uint64_t)dsp_in) / 8);
  if (depth >= 1 && dsp_in)
    tos = *(int64_t *)(uintptr_t)dsp_in;
  if (depth >= 2 && dsp_in)
    n1 = *(int64_t *)(uintptr_t)(dsp_in + 8);
  if (depth >= 3 && dsp_in)
    n2 = *(int64_t *)(uintptr_t)(dsp_in + 16);
  if (depth >= 4 && dsp_in)
    n3 = *(int64_t *)(uintptr_t)(dsp_in + 24);
  len = snprintf(line, sizeof line, "d=%-4lld %-6lld %-6lld %-6lld %-6lld",
                 (long long)depth, (long long)tos,
                 (long long)n1, (long long)n2, (long long)n3);
  if (len < 0) len = 0;
  for (i = 0; i < TCOM_COLS; i++)
    tcom_put_xy(i, y, (i < len) ? (uint8_t)line[i] : 32);
  return 0;
}

/* ( unused, DSP ) — memory cells below TOS; LIT always spills, so this is DEPTH */
static int64_t tcom_host_depth(int64_t a, int64_t dsp_in) {
  (void)a;
  if (!tcom_dsp0 || !dsp_in || (uint64_t)dsp_in > tcom_dsp0) return 0;
  return (int64_t)((tcom_dsp0 - (uint64_t)dsp_in) / 8);
}

static int64_t tcom_host_data0(int64_t a, int64_t b) {
  (void)a; (void)b;
  return (int64_t)(uintptr_t)tcom_data0;
}

static uint64_t tcom_sharp_hi;

static void tcom_pic_hold(uint8_t ch) {
  uint64_t hld;
  if (!tcom_data0) return;
  memcpy(&hld, tcom_data0 + 4888, 8);
  hld--;
  memcpy(tcom_data0 + 4888, &hld, 8);
  *(uint8_t *)(uintptr_t)hld = ch;
}

/* ( lo, hi ) → qlo; HOLDs one digit; qhi via slot 18 */
static int64_t tcom_host_sharp(int64_t lo, int64_t hi) {
  uint64_t base = 10, r;
  unsigned __int128 n, q;
  if (tcom_data0)
    memcpy(&base, tcom_data0 + 4880, 8);
  if (base < 2 || base > 36) base = 10;
  n = ((unsigned __int128)(uint64_t)hi << 64) | (uint64_t)lo;
  q = n / base;
  r = (uint64_t)(n % base);
  tcom_sharp_hi = (uint64_t)(q >> 64);
  tcom_pic_hold((uint8_t)((r < 10) ? ('0' + r) : ('A' + (r - 10))));
  return (int64_t)(uint64_t)q;
}

static int64_t tcom_host_sharphi(int64_t a, int64_t b) {
  (void)a; (void)b;
  return (int64_t)tcom_sharp_hi;
}

static uint64_t tcom_aux;
static uint64_t tcom_aux2;

static int64_t tcom_host_aux(int64_t a, int64_t b) {
  (void)a; (void)b;
  return (int64_t)tcom_aux;
}

static int64_t tcom_host_alloc(int64_t u, int64_t b) {
  void *p;
  (void)b;
  if (u < 0) { tcom_aux = -1; return 0; }
  p = malloc((size_t)u);
  tcom_aux = p ? 0 : -1;
  return (int64_t)(uintptr_t)p;
}

static int64_t tcom_host_free(int64_t addr, int64_t b) {
  (void)b;
  if (addr) free((void *)(uintptr_t)addr);
  tcom_aux = 0;
  return 0;
}

static int64_t tcom_host_resize(int64_t u, int64_t addr) {
  void *p2;
  if (u < 0) { tcom_aux = -1; return addr; }
  p2 = realloc((void *)(uintptr_t)addr, (size_t)u);
  if (!p2) { tcom_aux = -1; return addr; }
  tcom_aux = 0;
  return (int64_t)(uintptr_t)p2;
}

static int64_t tcom_host_umstar(int64_t u2, int64_t u1) {
  unsigned __int128 p = (unsigned __int128)(uint64_t)u1 * (uint64_t)u2;
  tcom_aux = (uint64_t)(p >> 64);
  return (int64_t)(uint64_t)p;
}

static int64_t tcom_host_mstar(int64_t n2, int64_t n1) {
  __int128 p = (__int128)n1 * n2;
  tcom_aux = (uint64_t)((__int128)p >> 64);
  return (int64_t)(uint64_t)p;
}

/* X0=den X1=hi X2=lo (third arg; Forth sets X2) */
static int64_t tcom_host_ummod(int64_t den, int64_t hi, int64_t lo) {
  unsigned __int128 n, d;
  if (den == 0) { tcom_aux = 0; return 0; }
  d = (uint64_t)den;
  n = ((unsigned __int128)(uint64_t)hi << 64) | (uint64_t)lo;
  tcom_aux = (uint64_t)(n / d);
  return (int64_t)(uint64_t)(n % d);
}

static int64_t tcom_host_smrem(int64_t den, int64_t hi, int64_t lo) {
  __int128 n, d, q, r;
  if (den == 0) { tcom_aux = 0; return 0; }
  n = hi;
  n = (n << 64) | (__int128)(uint64_t)lo;
  d = den;
  q = n / d;
  r = n % d;
  tcom_aux = (uint64_t)q;
  return (int64_t)r;
}

static int64_t tcom_host_fmmod(int64_t den, int64_t hi, int64_t lo) {
  __int128 n, d, q, r;
  if (den == 0) { tcom_aux = 0; return 0; }
  n = hi;
  n = (n << 64) | (__int128)(uint64_t)lo;
  d = den;
  q = n / d;
  r = n % d;
  if (r != 0 && ((n < 0) != (d < 0))) {
    q -= 1;
    r += d;
  }
  tcom_aux = (uint64_t)q;
  return (int64_t)r;
}

static int tcom_upc_ch(int c) {
  if (c >= 'a' && c <= 'z') return c - 32;
  return c;
}

static int64_t tcom_host_find(int64_t caddr, int64_t b) {
  uint64_t tab_d;
  uint8_t *tab, *want;
  uint64_t n, i;
  int wlen, nlen, k;
  (void)b;
  tcom_aux = 0;
  if (!tcom_data0 || !caddr) return caddr;
  memcpy(&tab_d, tcom_data0 + 5040, 8);
  if (!tab_d) return caddr;
  tab = tcom_data0 + (size_t)tab_d;
  memcpy(&n, tab, 8);
  want = (uint8_t *)(uintptr_t)caddr;
  wlen = want[0];
  if (wlen < 0) wlen = 0;
  tab += 8;
  for (i = 0; i < n; i++, tab += 48) {
    int64_t xt;
    int64_t flg;
    memcpy(&xt, tab, 8);
    memcpy(&flg, tab + 8, 8);
    nlen = tab[16];
    if (nlen != wlen) continue;
    for (k = 0; k < wlen; k++) {
      if (tcom_upc_ch(want[1 + k]) != tcom_upc_ch(tab[17 + k])) break;
    }
    if (k == wlen) {
      tcom_aux = (uint64_t)flg;
      return xt;
    }
  }
  return caddr;
}

static int64_t tcom_host_aux2(int64_t a, int64_t b) {
  (void)a; (void)b;
  return (int64_t)tcom_aux2;
}

static void tcom_path_copy(int64_t ca, int64_t u, char *buf, size_t cap) {
  size_t n = u < 0 ? 0 : (size_t)u;
  if (n >= cap) n = cap - 1;
  if (ca && n) memcpy(buf, (const void *)(uintptr_t)ca, n);
  buf[n] = 0;
}

static int tcom_fam_flags(int64_t fam, int create) {
  int acc = (int)(fam & 3);
  int fl = O_RDONLY;
  if (acc == 1) fl = O_WRONLY;
  else if (acc == 2) fl = O_RDWR;
  if (create) fl |= O_CREAT | O_TRUNC;
  return fl;
}

static int64_t tcom_host_openfile(int64_t ca, int64_t u, int64_t fam, int64_t create) {
  char path[512];
  int fd;
  tcom_path_copy(ca, u, path, sizeof path);
  fd = open(path, tcom_fam_flags(fam, create ? 1 : 0), 0644);
  if (fd < 0) { tcom_aux = (uint64_t)errno; return -1; }
  tcom_aux = 0;
  return fd;
}

static int64_t tcom_host_readfile(int64_t ca, int64_t u, int64_t fid) {
  ssize_t n;
  if (u < 0) u = 0;
  n = read((int)fid, (void *)(uintptr_t)ca, (size_t)u);
  if (n < 0) { tcom_aux = (uint64_t)errno; return 0; }
  tcom_aux = 0;
  return (int64_t)n;
}

static int64_t tcom_host_writefile(int64_t ca, int64_t u, int64_t fid) {
  ssize_t n;
  if (u < 0) u = 0;
  n = write((int)fid, (const void *)(uintptr_t)ca, (size_t)u);
  if (n < 0 || n != u) { tcom_aux = (uint64_t)(n < 0 ? errno : EIO); return (int64_t)tcom_aux; }
  tcom_aux = 0;
  return 0;
}

static int64_t tcom_host_readline(int64_t ca, int64_t u, int64_t fid) {
  uint8_t *buf = (uint8_t *)(uintptr_t)ca;
  int64_t n = 0;
  int got = 0;
  if (u < 0) u = 0;
  tcom_aux = 0;
  tcom_aux2 = 0;
  while (n < u) {
    unsigned char c;
    ssize_t r = read((int)fid, &c, 1);
    if (r < 0) { tcom_aux = (uint64_t)errno; tcom_aux2 = 0; return n; }
    if (r == 0) break;
    got = 1;
    if (c == '\n') break;
    if (c == '\r') {
      unsigned char c2;
      r = read((int)fid, &c2, 1);
      if (r == 1 && c2 != '\n') lseek((int)fid, -1, SEEK_CUR);
      break;
    }
    buf[n++] = c;
  }
  tcom_aux2 = got ? (uint64_t)-1 : 0;
  return n;
}

static int64_t tcom_host_writeline(int64_t ca, int64_t u, int64_t fid) {
  int64_t ior = tcom_host_writefile(ca, u, fid);
  if (ior) return ior;
  {
    ssize_t n = write((int)fid, "\n", 1);
    if (n != 1) { tcom_aux = (uint64_t)(n < 0 ? errno : EIO); return (int64_t)tcom_aux; }
  }
  tcom_aux = 0;
  return 0;
}

static int64_t tcom_host_deletefile(int64_t ca, int64_t u) {
  char path[512];
  tcom_path_copy(ca, u, path, sizeof path);
  if (unlink(path) < 0) { tcom_aux = (uint64_t)errno; return (int64_t)tcom_aux; }
  tcom_aux = 0;
  return 0;
}

static int64_t tcom_host_renamefile(int64_t ca1, int64_t u1, int64_t ca2, int64_t u2) {
  char a[512], b[512];
  tcom_path_copy(ca1, u1, a, sizeof a);
  tcom_path_copy(ca2, u2, b, sizeof b);
  if (rename(a, b) < 0) { tcom_aux = (uint64_t)errno; return (int64_t)tcom_aux; }
  tcom_aux = 0;
  return 0;
}

static int64_t tcom_host_fidop(int64_t fid, int64_t op) {
  off_t v;
  tcom_aux2 = 0;
  if (op == 2) {
    if (fsync((int)fid) < 0) { tcom_aux = (uint64_t)errno; return (int64_t)tcom_aux; }
    tcom_aux = 0;
    return 0;
  }
  if (op == 1) {
    v = lseek((int)fid, 0, SEEK_CUR);
  } else {
    off_t here = lseek((int)fid, 0, SEEK_CUR);
    if (here < 0) { tcom_aux = (uint64_t)errno; return 0; }
    v = lseek((int)fid, 0, SEEK_END);
    if (v >= 0) lseek((int)fid, here, SEEK_SET);
  }
  if (v < 0) { tcom_aux = (uint64_t)errno; return 0; }
  tcom_aux = 0;
  return (int64_t)v;
}

static int64_t tcom_host_offfid(int64_t off, int64_t fid, int64_t op) {
  if (op == 1) {
    if (ftruncate((int)fid, (off_t)off) < 0) { tcom_aux = (uint64_t)errno; return (int64_t)tcom_aux; }
  } else {
    if (lseek((int)fid, (off_t)off, SEEK_SET) < 0) { tcom_aux = (uint64_t)errno; return (int64_t)tcom_aux; }
  }
  tcom_aux = 0;
  return 0;
}

static int64_t tcom_host_filestat(int64_t ca, int64_t u) {
  char path[512];
  tcom_path_copy(ca, u, path, sizeof path);
  tcom_aux2 = 0;
  if (access(path, F_OK) < 0) { tcom_aux = (uint64_t)errno; return 0; }
  tcom_aux = 0;
  return 0;
}

static int64_t tcom_host_compare(int64_t ca1, int64_t u1, int64_t ca2, int64_t u2) {
  size_t n1 = u1 < 0 ? 0 : (size_t)u1, n2 = u2 < 0 ? 0 : (size_t)u2;
  size_t n = n1 < n2 ? n1 : n2;
  int r = 0;
  if (n && ca1 && ca2) r = memcmp((const void *)(uintptr_t)ca1, (const void *)(uintptr_t)ca2, n);
  if (r < 0) return -1;
  if (r > 0) return 1;
  if (n1 < n2) return -1;
  if (n1 > n2) return 1;
  return 0;
}

static int64_t tcom_host_search(int64_t ca1, int64_t u1, int64_t ca2, int64_t u2) {
  const uint8_t *h = (const uint8_t *)(uintptr_t)ca1;
  const uint8_t *n = (const uint8_t *)(uintptr_t)ca2;
  int64_t i;
  if (u2 <= 0) { tcom_aux = (uint64_t)ca1; tcom_aux2 = (uint64_t)u1; return -1; }
  if (u1 < u2) { tcom_aux = (uint64_t)ca1; tcom_aux2 = (uint64_t)u1; return 0; }
  for (i = 0; i <= u1 - u2; i++) {
    if (memcmp(h + i, n, (size_t)u2) == 0) {
      tcom_aux = (uint64_t)(ca1 + i);
      tcom_aux2 = (uint64_t)(u1 - i);
      return -1;
    }
  }
  tcom_aux = (uint64_t)ca1;
  tcom_aux2 = (uint64_t)u1;
  return 0;
}

#define TCOM_IN_OFF 5048
#define TCOM_SRC_OFF 5056
#define TCOM_SRCLEN_OFF 5064
#define TCOM_WORD_OFF 5072
#define TCOM_LINE_OFF 4104

static void tcom_src_get(uint8_t **ca, int64_t *u, int64_t *vin) {
  int64_t addr = 0, len = 0, inn = 0;
  if (!tcom_data0) { *ca = 0; *u = 0; *vin = 0; return; }
  memcpy(&addr, tcom_data0 + TCOM_SRC_OFF, 8);
  memcpy(&len, tcom_data0 + TCOM_SRCLEN_OFF, 8);
  memcpy(&inn, tcom_data0 + TCOM_IN_OFF, 8);
  if (!addr) addr = (int64_t)(uintptr_t)(tcom_data0 + TCOM_LINE_OFF);
  *ca = (uint8_t *)(uintptr_t)addr;
  *u = len;
  *vin = inn;
}

static int64_t tcom_host_parse(int64_t delim, int64_t b) {
  uint8_t *src;
  int64_t len, inn, j;
  (void)b;
  tcom_src_get(&src, &len, &inn);
  if (inn < 0) inn = 0;
  if (inn > len) inn = len;
  j = inn;
  while (j < len && src[j] != (uint8_t)delim) j++;
  tcom_aux = (uint64_t)(uintptr_t)(src + inn);
  {
    int64_t u = j - inn;
    if (j < len) j++;
    memcpy(tcom_data0 + TCOM_IN_OFF, &j, 8);
    return u;
  }
}

static int64_t tcom_host_word(int64_t delim, int64_t b) {
  uint8_t *src, *pad;
  int64_t len, inn, j, n;
  (void)b;
  if (!tcom_data0) return 0;
  tcom_src_get(&src, &len, &inn);
  if (inn < 0) inn = 0;
  if (inn > len) inn = len;
  while (inn < len && src[inn] == (uint8_t)delim) inn++;
  j = inn;
  while (j < len && src[j] != (uint8_t)delim) j++;
  n = j - inn;
  if (n > 255) n = 255;
  pad = tcom_data0 + TCOM_WORD_OFF;
  pad[0] = (uint8_t)n;
  if (n) memcpy(pad + 1, src + inn, (size_t)n);
  if (j < len) j++;
  memcpy(tcom_data0 + TCOM_IN_OFF, &j, 8);
  return (int64_t)(uintptr_t)pad;
}

static int64_t tcom_host_srcset(int64_t u, int64_t ca) {
  int64_t z = 0;
  if (!tcom_data0) return 0;
  memcpy(tcom_data0 + TCOM_SRC_OFF, &ca, 8);
  memcpy(tcom_data0 + TCOM_SRCLEN_OFF, &u, 8);
  memcpy(tcom_data0 + TCOM_IN_OFF, &z, 8);
  return 0;
}

static int64_t tcom_host_source(int64_t a, int64_t b) {
  uint8_t *src;
  int64_t len, inn;
  (void)a; (void)b;
  tcom_src_get(&src, &len, &inn);
  tcom_aux = (uint64_t)(uintptr_t)src;
  return len;
}

/* Slot order must match LIBARM64 HOST-CALL numbers */
static tcom_host_fn host_fn[] = {
  tcom_host_window,          /* 0 */
  tcom_host_app_name,        /* 1 */
  tcom_host_at,              /* 2 */
  tcom_host_cls,             /* 3 */
  tcom_host_getchar,         /* 4 */
  tcom_host_emit,            /* 5 */
  tcom_host_keyq,            /* 6 */
  tcom_host_key,             /* 7 */
  tcom_host_timer_reset,     /* 8 */
  tcom_host_tenths_elapsed,  /* 9 */
  tcom_host_tenths,          /* 10 */
  tcom_host_type,            /* 11 */
  tcom_host_tone,            /* 12 */
  tcom_host_dot,             /* 13 */
  tcom_host_stackhud,        /* 14 */
  tcom_host_depth,           /* 15 */
  tcom_host_data0,           /* 16 */
  tcom_host_sharp,           /* 17 */
  tcom_host_sharphi,         /* 18 */
  tcom_host_umstar,          /* 19 */
  tcom_host_mstar,           /* 20 */
  (tcom_host_fn)tcom_host_ummod,  /* 21  X2=lo */
  (tcom_host_fn)tcom_host_smrem,  /* 22  X2=lo */
  (tcom_host_fn)tcom_host_fmmod,  /* 23  X2=lo */
  tcom_host_aux,             /* 24 */
  tcom_host_alloc,           /* 25 */
  tcom_host_free,            /* 26 */
  tcom_host_resize,          /* 27 */
  tcom_host_find,            /* 28 */
  (tcom_host_fn)tcom_host_openfile,   /* 29 */
  (tcom_host_fn)tcom_host_readfile,   /* 30 */
  (tcom_host_fn)tcom_host_writefile,  /* 31 */
  (tcom_host_fn)tcom_host_readline,   /* 32 */
  tcom_host_aux2,                     /* 33 */
  (tcom_host_fn)tcom_host_writeline,  /* 34 */
  tcom_host_deletefile,               /* 35 */
  (tcom_host_fn)tcom_host_renamefile, /* 36 */
  tcom_host_fidop,                    /* 37 */
  (tcom_host_fn)tcom_host_offfid,     /* 38 */
  tcom_host_filestat,                 /* 39 */
  (tcom_host_fn)tcom_host_compare,    /* 40 */
  (tcom_host_fn)tcom_host_search,     /* 41 */
  tcom_host_parse,                    /* 42 */
  tcom_host_word,                     /* 43 */
  tcom_host_srcset,                   /* 44 */
  tcom_host_source,                   /* 45 */
};
