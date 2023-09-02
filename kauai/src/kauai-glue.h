// This header file is necessary to maintain until https://github.com/ziglang/zig/issues/9698 is resolved

#ifndef _KAUAI_GLUE
#define _KAUAI_GLUE

#ifdef __cplusplus
  #define EXPORT_C extern "C"
#else
  #define EXPORT_C
  #include <stdbool.h>
#endif

#ifndef max
#define max(a,b)            (((a) > (b)) ? (a) : (b))
#endif

#ifndef min
#define min(a,b)            (((a) < (b)) ? (a) : (b))
#endif

EXPORT_C bool ZigDecompress(void *pvSrc, long cbSrc, void *pvDst, long cbDst, long *pcbDst);
EXPORT_C bool ZigDecompress2(void *pvSrc, long cbSrc, void *pvDst, long cbDst, long *pcbDst);

#endif