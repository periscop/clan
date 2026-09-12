#pragma scop
for (i = 0; i < n; i++)
  A[B[i]++] = 0;
#pragma endscop
