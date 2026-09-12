#pragma scop
for (i = 0; i < n; i++)
  a[(((i % 3)))] = b[((i + 1) % 3)];
#pragma endscop
