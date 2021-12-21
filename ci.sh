#!/usr/bin/env bash

set -euo pipefail

ANOMA_REV=${ANOMA_REV:?Revision is required}
ANOMA_CHAIN_ID=${ANOMA_CHAIN_ID:-anoma-feigenbaum-0.ebb9e9f9013}
ANOMA_FEATURES=default
OUTPUT=stream-anoma-${ANOMA_REV}
registry=${CI_REGISTRY:-docker.io}
registry_auth=${CI_REGISTRY_AUTH:-} # NOTE: this needs to be in format: username:password
repo=heliaxdev/anoma

if meta=$(nix flake metadata --json "github:anoma/anoma/$ANOMA_REV"); then
	url=$(<<<"$meta" jq -r .url)
	rev=$(<<<"$meta" jq -r .revision)

	echo "Building from flake $url"

	nix-build image.nix --arg anoma "builtins.getFlake \"$url\"" -o "$OUTPUT"
else
	# Fetch anoma source
	anomaJson=$(nix-prefetch-github anoma anoma --rev "${ANOMA_REV}")
	anomaSrc=$(nix-instantiate -E "(import <nixpkgs> {}).fetchFromGitHub (builtins.fromJSON ''$anomaJson'')")
	rev=$(jq -r .rev <<<"$anomaJson")

	echo "No flake in $ANOMA_REV. Doing crate2nix instead"

	cargoNix=$(mktemp -p .)
	crate2nix generate \
		-f "$(nix-store -r "$anomaSrc")/Cargo.toml" \
		--no-default-features \
		--features "${ANOMA_FEATURES}" \
		-o "$cargoNix"

	# Build
	nix-build image.nix \
		--arg anomaSrc "$(nix-store -r "$anomaSrc")" \
		--arg cargoNix "$cargoNix" \
		--argstr ANOMA_FEATURES "${ANOMA_FEATURES}" \
		--argstr ANOMA_CHAIN_ID "${ANOMA_CHAIN_ID}" \
		-o "$OUTPUT"
	rm "$cargoNix"
fi

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

tag=${IMAGE_TAG:-"$(date +%F).${rev::12}"}
tag=$(echo -n "$tag" | tr -cs '[:alnum:]-._' '_')
dst=docker://$registry/$repo:$tag

echo "Copying image $repo:$tag to registry $registry"

./"$OUTPUT" | gzip | skopeo copy --insecure-policy docker-archive:/dev/stdin "$dst"
