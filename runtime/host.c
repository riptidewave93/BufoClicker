#include <stdlib.h>
#ifdef __EMSCRIPTEN__
#include <emscripten.h>
int h_is_browser(void) { return 1; }
EM_JS(int, h_random, (double *output), {
    HEAPF64[output >> 3] = Math.random();
    return 0;
});
EM_JS(int, h_now, (double *output), {
    HEAPF64[output >> 3] = Date.now();
    return 0;
});
#else
#include <time.h>
int h_is_browser(void) { return 0; }
int h_random(double *output) {
    *output = (double)rand() / ((double)RAND_MAX + 1.0);
    return 0;
}
int h_now(double *output) {
    struct timespec now;
    if (clock_gettime(CLOCK_REALTIME, &now)) return -1;
    *output = (double)now.tv_sec * 1000.0 + (double)now.tv_nsec / 1000000.0;
    return 0;
}
#endif
