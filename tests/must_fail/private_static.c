#pragma scop
for (i = 0; i < n; i++) {
  static int x;
}
#pragma endscop
