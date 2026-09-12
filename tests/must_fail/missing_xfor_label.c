#pragma scop
xfor (i = 0, j = 0; i < n, j < n; i++, j++)
  a[i] = 0;
#pragma endscop
