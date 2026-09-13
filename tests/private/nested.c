#pragma scop
int global = input;
for (i = 0; i < n; i++) {
  double outer;
  outer = a[i];
  for (j = 0; j < n; j++) {
    const float inner = outer + b[j];
    for (k = 0; k < n; k++) {
      outer += inner;
      c[i][j][k] = outer;
    }
  }
  global += outer;
}
result = global;
#pragma endscop
