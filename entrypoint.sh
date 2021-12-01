#!/bin/sh

set -e

for file in /docker-entrypoint.d/*; do
	if [ -x "$file" ]; then
		echo "Executing '$file'" >&2
		"$file"
	fi
done

exec "$@"
