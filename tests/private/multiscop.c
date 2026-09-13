#pragma scop
float value;
a[0] = value;
#pragma endscop
#pragma scop
for (i = 0; i < n; i++) {
  float value = a[i];
  b[i] = value;
}
#pragma endscop
