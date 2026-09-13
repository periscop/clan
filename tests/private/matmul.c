#pragma scop
for (i = 0; i < n; i++) {
  for (j = 0; j < n; j++) {
    float acc = 0;
    for (k = 0; k < n; k++) {
      acc += a[i][k] * b[k][j];
    }
    c[i][j] = acc;
  }
}
#pragma endscop
