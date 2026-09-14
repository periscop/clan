#pragma scop
for (size_t i = 0; i < n; ++i)
  for (int j = 1; j < m; j += 2)
    A[i][j] = i + j;
#pragma endscop
