#!/bin/sh
# Check strict subscript rejection, retained affine accesses, and SCoP discovery.
set -eu
clan="$top_builddir/clan${EXEEXT:-}"
work=$(mktemp -d "${TMPDIR:-/tmp}/clan-affine-only.XXXXXX")
trap 'rm -rf "$work"' 0
trap 'exit 1' HUP INT TERM

for input in "$srcdir"/nonaffine/*.c; do
  for option in '' -extbody; do
    "$clan" -affine-only $option "$input" -o "$work/out" > "$work/info" 2> "$work/err"
    grep -q 'non-affine array subscript with -affine-only' "$work/err"
    printf '# NULL scop\n' > "$work/expected"
    cmp "$work/expected" "$work/out"
  done
done

for input in "$srcdir"/modulo_acess/*.c "$srcdir"/unitary/field.c; do
  "$clan" "$input" > "$work/expected"
  "$clan" -affine-only "$input" > "$work/out"
  cmp "$work/expected" "$work/out"
done

cat > "$work/input.c" <<'EOF'
void test(void) {
  for (i = 0; i < n; i++)
    A[B[i]] = 0;
  for (j = 0; j < n; j++)
    C[j] = f(D[j]);
}
EOF
"$clan" -affine-only -autoscop "$work/input.c" > "$work/out"
sed '/A\[B\[i\]\]/s/.*/    break;/' "$work/input.c" > "$work/filtered"
mv "$work/filtered" "$work/input.c"
"$clan" -autoscop "$work/input.c" > "$work/expected"
cmp "$work/expected" "$work/out"
echo '[PASS] Affine-only option'
