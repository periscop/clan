#pragma scop
for (i = 0; i < n; i++)
  for (j = 0; j < n; j++) {
    A[f(B[i],j,C[2*i+j+3*n-2])][j] = 0;
    A[f()][g(j)] = A[h(B[i]) % 3];
    A[B[i] ? C[j] : D[i+j]] = 0;
    A[B[i]][j % 3][i+1] = C[i];
    A[(int)B[i]] = 0;
  }
#pragma endscop
