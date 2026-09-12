#pragma scop
for (i = 0; i < n; i++, i++)
  a[i] = 0;
#pragma endscop
