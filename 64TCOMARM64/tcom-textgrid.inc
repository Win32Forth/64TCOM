/* tcom-textgrid.inc — pasted into TCOM GUI .m by MACHOARM64
 * 80x25 DOS-style text grid + host_fn[] for AT/CLS/EMIT/GET-CHAR/KEY?/KEY/timers/TYPE/DOT/TONE
 * Public domain.
 */
#include <sys/time.h>
#include <unistd.h>
#include <ctype.h>
#include <stdio.h>

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
static uint64_t tcom_dsp0 = 0;
static uint64_t tcom_dsp_min = ~(uint64_t)0;
static int tcom_dsp_reports = 0;

/* b = Forth DSP (X19) from KEY?/10TH-ELAPSED. Track growth (DSP descends). */
static int tcom_dsp_samples = 0;
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
  if (c >= 0) tcom_key_push(c);
}
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

@interface TcomAppDelegate : NSObject <NSApplicationDelegate>
@end
@implementation TcomAppDelegate
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  (void)sender; return YES;
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
  TcomGridView *view = [[TcomGridView alloc] initWithFrame:NSMakeRect(0, 0, w, h)];
  [view setWantsLayer:YES];
  tcom_grid_view = view;
  [tcom_window setContentView:view];
  [tcom_window makeKeyAndOrderFront:nil];
  [tcom_window makeFirstResponder:view];
  [app activateIgnoringOtherApps:YES];
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
  tcom_pump();
  if (tcom_kr != tcom_kw) return -1;
  /* Busy-wait yield — MOVEMENT spins on KEY? until drop time */
  usleep(1000);
  return 0;
}

static int64_t tcom_host_key(int64_t a, int64_t b) {
  (void)a; (void)b;
  for (;;) {
    tcom_pump();
    int64_t c = tcom_key_pop();
    if (c >= 0) return c;
    /* Block briefly waiting for input */
    @autoreleasepool {
      NSEvent *e = [NSApp nextEventMatchingMask:NSEventMaskAny
                                      untilDate:[NSDate dateWithTimeIntervalSinceNow:0.05]
                                         inMode:NSDefaultRunLoopMode
                                        dequeue:YES];
      if (e) [NSApp sendEvent:e];
    }
  }
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
  gettimeofday(&tcom_t0, NULL);
  while (tcom_tenths_now() < n) {
    tcom_pump();
    @autoreleasepool {
      NSEvent *e = [NSApp nextEventMatchingMask:NSEventMaskAny
                                      untilDate:[NSDate dateWithTimeIntervalSinceNow:0.01]
                                         inMode:NSDefaultRunLoopMode
                                        dequeue:YES];
      if (e) [NSApp sendEvent:e];
    }
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

/* TONE: freq = Hz, dur = tenths of a second (F-PC). Stub beeps; ignores both. */
static int64_t tcom_host_tone(int64_t freq, int64_t dur) {
  (void)freq; (void)dur;
  NSBeep();
  tcom_pump();
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
};
