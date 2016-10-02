/*
 * 'Fake' math.h to be included by terra.
 */
#ifndef TRUSS_MATH_H
#define TRUSS_MATH_H

/*
 * Used by truss to check whether this header has been included from compat
 * or from the actual system includes
 */
#define TRUSS_CHECK_MATH 7777

int abs(int);
double acos(double);
float acosf(float);
double acosh(double);
float acoshf(float);
double asin(double);
float asinf(float);
double asinh(double);
float asinhf(float);
double atan(double);
float atanf(float);
double atanh(double);
float atanhf(float);
double atan2(double, double);
float atan2f(float, float);
double atof(const char*);
double cbrt(double);
float cbrtf(float);
double ceil(double);
float ceilf(float);
double copysign(double, double);
float copysignf(float, float);
double cos(double);
float cosf(float);
double cosh(double);
float coshf(float);
double erf(double);
float erff(float);
double erfc(double);
float erfcf(float);
double exp(double);
float expf(float);
double exp2(double);
float exp2f(float);
double expm1(double);
float expm1f(float);
double fabs(double);
double fdim(double, double);
float fdimf(float, float);
float floorf(float);
double floor(double);
double fma(double, double, double);
float fmaf(float, float, float);
double fmax(double, double);
float fmaxf(float, float);
double fmin(double, double);
float fminf(float, float);
double fmod(double, double);
double frexp(double, int*);
int ilogb(double);
int ilogbf(float);
long labs(long);
double ldexp(double, int);
long long llabs(long long);
double lgamma(double);
float lgammaf(float);
long long llrint(double);
long long llrintf(float);
long long llround(double);
long long llroundf(float);
double log(double);
double log10(double);
double log1p(double);
float log1pf(float);
double log2(double);
float log2f(float);
double logb(double);
float logbf(float);
long lrint(double);
long lrintf(float);
long lround(double);
long lroundf(float);
double modf(double, double*);
double nan(const char*);
float nanf(const char*);
double nearbyint(double);
float nearbyintf(float);
double nextafter(double, double);
float nextafterf(float, float);
double nexttoward(double, long double);
float nexttowardf(float, long double);
double pow(double, double);
float powf(float, float);
double remainder(double, double);
float remainderf(float, float);
double remquo(double, double, int*);
float remquof(float, float, int*);
double rint(double);
float rintf(float);
double round(double);
float roundf(float);
double scalbln(double, long);
float scalblnf(float, long);
double scalbn(double, int);
float scalbnf(float, int);
double sin(double);
float sinf(float);
double sinh(double);
double sqrt(double);
float sqrtf(float);
double tan(double);
float tanf(float);
double tanh(double);
double tgamma(double);
float tgammaf(float);
double trunc(double);
float truncf(float);

#endif /* TRUSS_MATH_H */
