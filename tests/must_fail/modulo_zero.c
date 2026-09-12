#pragma scop
for (i = 0; i < n; i++)
  a[i % 0] = 0;
#pragma endscop
