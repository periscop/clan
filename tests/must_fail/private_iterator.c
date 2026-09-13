#pragma scop
for (i = 0; i < n; i++) {
  int x; for (x = 0; x < n; x++) { a[x] = 0; }
}
#pragma endscop
