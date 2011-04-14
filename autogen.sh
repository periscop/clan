#!/bin/sh
autoreconf -i
if test -f osl/autogen.sh; then
	(cd osl; ./autogen.sh)
fi
