#pragma scop
for (i = 0; i < n; i++)
  if (i < m)
    a[i] = 0;
  else
    i = n;
#pragma endscop
