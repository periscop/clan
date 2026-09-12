#pragma scop
for (i = 0; i < n; i++)
  a[i][(i + 1) % 3][i % 2][0] = 0;
#pragma endscop
