#!/bin/sh
# Ensure matching reference output cannot hide process/sanitizer failures.
set -eu
checker=${CHECKER:-${1:-}}
test -n "$checker"
test_dir=$(mktemp -d "${TMPDIR:-/tmp}/clan-checker.XXXXXX")
trap 'rm -rf "$test_dir"' EXIT HUP INT TERM
cat > "$test_dir/clan" <<'CLAN'
#!/bin/sh
case "$(cat "$1")" in
  ok) echo 'ordinary parser diagnostic' >&2 ;;
  exit) exit 1 ;;
  asan) echo 'ERROR: AddressSanitizer: heap-buffer-overflow' >&2 ;;
  leak) echo 'ERROR: LeakSanitizer: detected memory leaks' >&2 ;;
esac
CLAN
chmod +x "$test_dir/clan"
for kind in ok exit asan leak; do
  printf '%s\n' "$kind" > "$test_dir/$kind.c"
  : > "$test_dir/$kind.c.scop"
done
run_checker() {
  top_builddir="$test_dir" EXEEXT= sh "$checker" regression "$1" "" clan > "$test_dir/log" 2>&1
}
if ! run_checker "$test_dir/ok.c"; then
  cat "$test_dir/log"
  exit 1
fi
grep -q 'ordinary parser diagnostic' "$test_dir/log"
for kind in exit asan leak; do
  if run_checker "$test_dir/$kind.c $test_dir/ok.c"; then
    echo "Checker incorrectly accepted $kind followed by success"
    cat "$test_dir/log"
    exit 1
  fi
  if [ "$kind" = asan ]; then
    grep -q 'ERROR: AddressSanitizer: heap-buffer-overflow' "$test_dir/log"
  fi
done

# A fake leaks executable keeps these harness tests portable (including Linux).
cat > "$test_dir/leaks" <<'LEAKS'
#!/bin/sh
test "$1" = --atExit && test "$2" = -- || exit 2
shift 3
test "${1:-}" = -autoinsert && shift
case "$(cat "$1")" in
  ok) echo 'Process 123: 0 leaks for 0 total leaked bytes.' ;;
  leak) echo 'Process 123: 1 leaks for 16 total leaked bytes.'; exit 1 ;;
  exit) echo 'Unable to inspect process'; exit 2 ;;
  asan) : ;; # A zero status without a completed scan must not pass.
esac
LEAKS
chmod +x "$test_dir/leaks"
run_leaks_checker() {
  PATH="$test_dir:$PATH" top_builddir="$test_dir" EXEEXT= \
    sh "$checker" regression "$1" -autoinsert leaks > "$test_dir/log" 2>&1
}
run_leaks_checker "$test_dir/ok.c"
for kind in leak exit asan; do
  if run_leaks_checker "$test_dir/$kind.c $test_dir/ok.c"; then
    echo "Leak checker incorrectly accepted $kind followed by success"
    exit 1
  fi
done
echo 'Checker failure propagation tests passed'
