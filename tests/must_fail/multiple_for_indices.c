#pragma scop
for (i = 0, j = 0; i < n, j < n; i++, j++)
  a[i][j] = 0;
#pragma endscop
