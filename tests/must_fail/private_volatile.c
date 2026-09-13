#pragma scop
for (i = 0; i < n; i++) {
  volatile int x;
}
#pragma endscop
