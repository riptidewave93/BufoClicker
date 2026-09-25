#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/* Expand the shortest round-tripping decimal, then round its decimal digits.
 * This is the decimal input convention used by Intl.NumberFormat. */
int h_decimal(const double *value, int decimals, int grouping, int trim,
              char *out, int capacity) {
    if (capacity < 0) return -1;
    memset(out, ' ', (size_t)capacity);
    if (!isfinite(*value) || decimals < 0 || decimals > 100) return -1;
    char shortest[64];
    double magnitude = fabs(*value);
    for (int precision = 1; precision <= 17; ++precision) {
        snprintf(shortest, sizeof shortest, "%.*g", precision, magnitude);
        if (strtod(shortest, NULL) == magnitude) break;
    }
    char *exponent = strchr(shortest, 'e');
    int scale = exponent ? atoi(exponent + 1) : 0;
    if (exponent) *exponent = 0;
    char digits[64]; int count = 0, whole = 0, seen_dot = 0;
    for (char *p = shortest; *p; ++p) {
        if (*p == '.') { seen_dot = 1; continue; }
        digits[count++] = *p;
        if (!seen_dot) whole++;
    }
    whole += scale;
    char fixed[768]; memset(fixed, '0', sizeof fixed);
    int integral = whole > 0 ? whole : 1;
    int length = integral + decimals;
    if (length + 2 >= (int)sizeof fixed) return -1;
    for (int position = 0; position < length; ++position) {
        int source = position + whole - integral;
        if (source >= 0 && source < count) fixed[position] = digits[source];
    }
    int next = length + whole - integral;
    if (next >= 0 && next < count && digits[next] >= '5') {
        int at = length - 1;
        while (at >= 0 && fixed[at] == '9') fixed[at--] = '0';
        if (at >= 0) fixed[at]++;
        else { memmove(fixed + 1, fixed, length); fixed[0] = '1'; length++; integral++; }
    }
    if (trim) while (length > integral && fixed[length - 1] == '0') length--;
    char formatted[1024]; int used = 0;
    if (signbit(*value)) formatted[used++] = '-';
    for (int i = 0; i < length; ++i) {
        if (i == integral) formatted[used++] = '.';
        formatted[used++] = fixed[i];
        if (grouping && i < integral - 1 && (integral - i - 1) % 3 == 0)
            formatted[used++] = ',';
    }
    if (used > capacity) return -1;
    memcpy(out, formatted, (size_t)used);
    return 0;
}
