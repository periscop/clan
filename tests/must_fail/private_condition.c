#pragma scop
for (i = 0; i < n; i++) {
  int x; if (x > 0) { a[i] = 0; }
}
#pragma endscop
