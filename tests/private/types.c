#pragma scop
for (i = 0; i < n; i++) {
  char c;
  signed char sc;
  unsigned char uc;
  short s;
  unsigned short int us;
  int x;
  signed sx;
  unsigned ux;
  long l;
  unsigned long int ul;
  long long ll;
  long unsigned long int ull;
  float f;
  double d;
  long double ld;
  _Bool boolean;
  float _Complex fc;
  _Complex double dc;
  long _Complex double ldc;
  float _Imaginary fi;
  int const constant = a[i];
}
#pragma endscop
