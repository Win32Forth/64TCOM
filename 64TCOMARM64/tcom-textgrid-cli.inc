/* tcom-textgrid-cli.inc — pasted into TCOM-CLI .c by MACHOARM64
 * Same host_fn slot indices as GUI; screen ops stubbed / stdio.
 * Public domain.
 */
#include <sys/time.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef int64_t (*tcom_host_fn)(int64_t, int64_t);

uint8_t *tcom_dsp_floor = 0;
uint64_t tcom_dsp0 = 0;
uint8_t *tcom_data0 = 0;
static int tcom_gui_opened = 0;
static char tcom_app_name[256] = "64TCOM";
static int tcom_cx = 0, tcom_cy = 0;
static struct timeval tcom_t0;

static int64_t tcom_host_window(int64_t a, int64_t b) {
  (void)a; (void)b; (void)tcom_gui_opened; return -1;
}

static int64_t tcom_host_app_name(int64_t ca, int64_t u) {
  size_t n = (size_t)u; if (n > 255u) n = 255u;
  if (!ca || n == 0) { strcpy(tcom_app_name, "64TCOM"); return 0; }
  memcpy(tcom_app_name, (const void *)(uintptr_t)ca, n); tcom_app_name[n] = 0; return 0;
}

static int64_t tcom_host_at(int64_t x, int64_t y) {
  tcom_cx = (int)x; tcom_cy = (int)y; return 0;
}

static int64_t tcom_host_cls(int64_t a, int64_t b) {
  (void)a; (void)b; tcom_cx = tcom_cy = 0; return 0;
}

static int64_t tcom_host_getchar(int64_t a, int64_t b) {
  (void)a; (void)b; return 219; /* open cell for TETRA */
}

static int64_t tcom_host_emit(int64_t c, int64_t b) {
  (void)b;
  unsigned char ch = (unsigned char)(c & 255);
  if (c == 10 || c == 13) { write(1, "\n", 1); return 0; }
  write(1, &ch, 1);
  return 0;
}

static int64_t tcom_host_keyq(int64_t a, int64_t b) {
  (void)a; (void)b; return 0; /* no non-blocking stdin */
}

static int64_t tcom_host_key(int64_t a, int64_t b) {
  (void)a; (void)b;
  unsigned char ch;
  ssize_t n = read(0, &ch, 1);
  return (n == 1) ? (int64_t)ch : -1;
}

static int64_t tcom_host_timer_reset(int64_t a, int64_t b) {
  (void)a; (void)b; gettimeofday(&tcom_t0, NULL); return 0;
}

static int64_t tcom_tenths_now(void) {
  struct timeval now;
  gettimeofday(&now, NULL);
  int64_t us = (int64_t)(now.tv_sec - tcom_t0.tv_sec) * 1000000LL
             + (int64_t)(now.tv_usec - tcom_t0.tv_usec);
  if (us < 0) us = 0;
  return us / 100000LL;
}

static int64_t tcom_host_tenths_elapsed(int64_t a, int64_t b) {
  (void)a; (void)b; return tcom_tenths_now();
}

static int64_t tcom_host_tenths(int64_t n, int64_t b) {
  (void)b;
  if (n < 0) n = 0;
  gettimeofday(&tcom_t0, NULL);
  while (tcom_tenths_now() < n) {
    struct timespec ts; ts.tv_sec = 0; ts.tv_nsec = 10 * 1000 * 1000;
    nanosleep(&ts, NULL);
  }
  return 0;
}

static int64_t tcom_host_type(int64_t ca, int64_t u) {
  if (!ca || u <= 0) return 0;
  write(1, (const void *)(uintptr_t)ca, (size_t)u);
  return 0;
}

static int64_t tcom_host_tone(int64_t freq, int64_t dur) {
  (void)freq; (void)dur; return 0;
}

static int64_t tcom_host_dot(int64_t n, int64_t b) {
  (void)b;
  char buf[32];
  int len = snprintf(buf, sizeof buf, "%lld", (long long)n);
  if (len > 0) write(1, buf, (size_t)len);
  return 0;
}

static int64_t tcom_host_stackhud(int64_t line_y, int64_t b) {
  (void)line_y; (void)b;
  return 0;
}

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

static tcom_host_fn host_fn[] = {
  tcom_host_window,
  tcom_host_app_name,
  tcom_host_at,
  tcom_host_cls,
  tcom_host_getchar,
  tcom_host_emit,
  tcom_host_keyq,
  tcom_host_key,
  tcom_host_timer_reset,
  tcom_host_tenths_elapsed,
  tcom_host_tenths,
  tcom_host_type,
  tcom_host_tone,
  tcom_host_dot,
  tcom_host_stackhud,
  tcom_host_depth,
  tcom_host_data0,
  tcom_host_sharp,
  tcom_host_sharphi,
  tcom_host_umstar,
  tcom_host_mstar,
  (tcom_host_fn)tcom_host_ummod,
  (tcom_host_fn)tcom_host_smrem,
  (tcom_host_fn)tcom_host_fmmod,
  tcom_host_aux,
  tcom_host_alloc,
  tcom_host_free,
  tcom_host_resize,
};
