#!/usr/bin/env bash

set -euo pipefail

export ANOMA_REV=${ANOMA_REV:-v0.2.0}

registry=${CI_REGISTRY:-docker.io}
registry_auth=${CI_REGISTRY_AUTH:-} # NOTE: this needs to be in format: username:password

tag=$(date +%F) # XXX

echo Build image
make

if [[ -n $registry_auth ]]; then
	echo docker login
	mkdir -p ~/.docker
	if [[ $registry = *docker.io ]]; then
		registry_index=https://index.docker.io/v2/
	fi
	cat <<DOCKER_CONF > ~/.docker/config.json
	{
		"auths": {
			"$registry_index": {
				"auth": "$(echo -n "$registry_auth" | base64)"
			}
		}
	}
DOCKER_CONF
fi

echo "Push to $registry"
src=./stream-anoma-$ANOMA_REV
dst=docker://docker.io/heliaxdev/anoma:$tag

"$src" | skopeo copy --insecure-policy docker-archive:/dev/stdin "$dst"
