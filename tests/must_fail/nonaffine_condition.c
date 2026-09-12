#pragma scop
for (i = 0; i < n; i++)
  if (B[i]) A[i] = 0;
#pragma endscop
