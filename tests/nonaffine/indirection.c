#pragma scop
for (i = 0; i < n; i++)
  for (j = 0; j < n; j++) {
    A[B[i]][j] = 0;
    X[i] = A[B[C[i]]][D[j]];
    A[B[i]][j] += D[E[i]];
    A[B[i]][j]++;
    ++A[B[i]][j];
    A[B[i]].field = D[E[i]].field;
  }
#pragma endscop
