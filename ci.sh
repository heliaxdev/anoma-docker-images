#!/usr/bin/env bash

set -euo pipefail

ANOMA_REV=${ANOMA_REV:?Revision is required}
ANOMA_CHAIN_ID=${ANOMA_CHAIN_ID:-anoma-feigenbaum-0.ebb9e9f9013}
OUTPUT=stream-anoma-${ANOMA_REV}
CARGO_NIX=Cargo-${ANOMA_REV}.nix
ANOMA_SRC=anoma-src.${ANOMA_REV}.json
ANOMA_FEATURES=default

registry=${CI_REGISTRY:-docker.io}
registry_auth=${CI_REGISTRY_AUTH:-} # NOTE: this needs to be in format: username:password

repo=heliaxdev/anoma

# Fetch anoma source
nix-prefetch-github anoma anoma --rev "${ANOMA_REV}" > "$ANOMA_SRC"
anomaSrc=$(nix-instantiate --argstr ANOMA_REV "${ANOMA_REV}" ./anoma-src.nix)
anomaRevHash=$(jq -r .rev "$ANOMA_SRC")
tag=${IMAGE_TAG:-"$(date +%F).${anomaRevHash::12}"}
tag=$(echo -n "$tag" | tr -cs '[:alnum:]-._' '_')

echo "Building image $repo:$tag from github:anoma/anoma/$ANOMA_REV"

# Create Cargo.nix
crate2nix generate \
	-f "$(nix-store -r "$anomaSrc")/Cargo.toml" \
	--no-default-features --features "${ANOMA_FEATURES}" \
	-o "$CARGO_NIX"

# Build
nix-build ci.nix -j auto \
  --argstr ANOMA_REV "${ANOMA_REV}" \
  --argstr ANOMA_CHAIN_ID "${ANOMA_CHAIN_ID}" \
  --argstr ANOMA_FEATURES "${ANOMA_FEATURES}" \
  -o "$OUTPUT"

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

dst=docker://$registry/$repo:$tag

echo "Copying image $repo:$tag to registry $registry"

./"$OUTPUT" | gzip | skopeo copy --insecure-policy docker-archive:/dev/stdin "$dst"
