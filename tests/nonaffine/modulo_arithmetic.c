#pragma scop
for (i = 0; i < n; i++)
  a[i + 1 % 3] = 0;
#pragma endscop
