#pragma scop
for (i = n - 1; i >= 0; i -= 2) {
  if (i >= 2) {
    int left = a[index[i]];
    left++;
    b[left] = left;
  } else {
    int right;
    ++right;
    b[i] = right;
  }
}
#pragma endscop
