/* tcom-textgrid-cli.inc — pasted into TCOM-CLI .c by MACHOARM64
 * Same host_fn slot indices as GUI; screen ops stubbed / stdio.
 * Public domain.
 */
#include <sys/time.h>
#include <time.h>
#include <unistd.h>
#include <stdio.h>

typedef int64_t (*tcom_host_fn)(int64_t, int64_t);

uint8_t *tcom_dsp_floor = 0;
uint64_t tcom_dsp0 = 0;
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
};
