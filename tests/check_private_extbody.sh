#!/bin/sh
"$CHECKER" "Private variable test suite" "$PRIVATE_TEST_FILES" "-extbody" "${1:-clan}"
