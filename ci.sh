#!/usr/bin/env bash

set -euo pipefail

export ANOMA_REV=${ANOMA_REV:?ANOMA_REV was not specified}

registry=${CI_REGISTRY:-docker.io}
registry_auth=${CI_REGISTRY_AUTH:-} # NOTE: this needs to be in format: username:password

repo=heliaxdev/anoma
tag=${IMAGE_TAG:-"$(date +%F).${ANOMA_REV::12}"}
tag=$(echo -n "$tag" | tr -cs '[:alnum:]-._' '_')

echo "Building image $repo:$tag from github:anoma/anoma/$ANOMA_REV"
echo "Image will be tagged $repo:$tag and pushed to registry $registry"

# nix-prefetch-github has a hard-coded <nixpkgs> reference
nixpkgs=$(nix eval --raw -f ./nixpkgs.nix)
export NIX_PATH=nixpkgs=$nixpkgs
make

if [[ -n $registry_auth ]]; then
	echo docker login
	mkdir -p ~/.docker
	if [[ $registry = *docker.io ]]; then
		registry_index=https://index.docker.io/v2/
	fi
	cat <<DOCKER_CONF > ~/.docker/config.json
{ "auths": { "$registry_index": { "auth": "$(echo -n "$registry_auth" | base64)" } } }
DOCKER_CONF
fi

src=./stream-anoma-$ANOMA_REV
dst=docker://$registry/$repo:$tag

echo "Copying image to $dst"

"$src" | gzip | skopeo copy --insecure-policy docker-archive:/dev/stdin "$dst"
