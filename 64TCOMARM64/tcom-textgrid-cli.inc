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
#include <fcntl.h>
#include <errno.h>

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

/* FIND (counted string at runtime addr). Table daddr in data[5040].
 * Returns xt (or caddr if missing); tcom_aux = 0 | 1 (imm) | -1. */
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

/* X0=caddr X1=u X2=fam X3=create. Return fid; aux=ior */
static int64_t tcom_host_openfile(int64_t ca, int64_t u, int64_t fam, int64_t create) {
  char path[512];
  int fd;
  tcom_path_copy(ca, u, path, sizeof path);
  fd = open(path, tcom_fam_flags(fam, create ? 1 : 0), 0644);
  if (fd < 0) { tcom_aux = (uint64_t)errno; return -1; }
  tcom_aux = 0;
  return fd;
}

/* X0=caddr X1=u X2=fid. Return u2; aux=ior */
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

/* Return u2; aux=ior; aux2=flag (0 or -1) */
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

/* X0=ca1 X1=u1 X2=ca2 X3=u2 */
static int64_t tcom_host_renamefile(int64_t ca1, int64_t u1, int64_t ca2, int64_t u2) {
  char a[512], b[512];
  tcom_path_copy(ca1, u1, a, sizeof a);
  tcom_path_copy(ca2, u2, b, sizeof b);
  if (rename(a, b) < 0) { tcom_aux = (uint64_t)errno; return (int64_t)tcom_aux; }
  tcom_aux = 0;
  return 0;
}

/* X0=fid  X1=op  0=size 1=pos 2=flush. size/pos → X0=lo aux2=hi; flush → 0. aux=ior */
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

/* X0=off X1=fid X2=op  0=repos 1=trunc */
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
  tcom_aux2 = 0; /* x */
  if (access(path, F_OK) < 0) { tcom_aux = (uint64_t)errno; return 0; }
  tcom_aux = 0;
  return 0;
}

/* COMPARE (ca1 u1 ca2 u2) X0=ca1 X1=u1 X2=ca2 X3=u2 → -1/0/1 */
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

/* SEARCH: X0=ca1 X1=u1 X2=ca2 X3=u2. Return flag; aux=caddr3 aux2=u3 */
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

/* PARSE delim in X0. Return u; aux=caddr */
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

/* WORD delim in X0. Return counted c-addr */
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

/* SOURCE! X0=u X1=caddr */
static int64_t tcom_host_srcset(int64_t u, int64_t ca) {
  int64_t z = 0;
  if (!tcom_data0) return 0;
  memcpy(tcom_data0 + TCOM_SRC_OFF, &ca, 8);
  memcpy(tcom_data0 + TCOM_SRCLEN_OFF, &u, 8);
  memcpy(tcom_data0 + TCOM_IN_OFF, &z, 8);
  return 0;
}

/* SOURCE: return u; aux=caddr */
static int64_t tcom_host_source(int64_t a, int64_t b) {
  uint8_t *src;
  int64_t len, inn;
  (void)a; (void)b;
  tcom_src_get(&src, &len, &inn);
  tcom_aux = (uint64_t)(uintptr_t)src;
  return len;
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
  tcom_host_find,
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
