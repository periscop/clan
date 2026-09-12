#pragma scop
for (i = 0; i < n; i++)
  i[(i % 3)] = 0;
#pragma endscop
