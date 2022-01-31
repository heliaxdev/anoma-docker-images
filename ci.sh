#!/usr/bin/env bash

set -euo pipefail

ANOMA_CHAIN_ID=${ANOMA_CHAIN_ID:-anoma-feigenbaum-0.ebb9e9f9013}
ANOMA_FEATURES=${ANOMA_FEATURES:-default} # NOTE: does nothing when the flake build is used

while [[ $# -gt 0 ]]; do
	case $1 in
		--no-upload) UPLOAD=; shift ;;
		--rev) ANOMA_REV=$2; shift 2 ;;
		-o) OUTPUT=$2; shift 2 ;;
		*) echo "usage: $(basename "$0") [--no-upload] [--rev ANOMA_REV] [-o FILE]" >&2; exit 2 ;;
	esac
done

rev=${ANOMA_REV:?Revision is required}
upload=${UPLOAD-y}
registry=${CI_REGISTRY:-docker.io}
registry_auth=${CI_REGISTRY_AUTH:-} # NOTE: this needs to be in format: username:password
repo=${IMAGE_REPO:-heliaxdev/anoma}
output=${OUTPUT:-"stream-anoma-$(echo -n "$rev" | tr -cs '[:alnum:]-._' '-')"}

if meta=$(nix flake metadata --json "github:anoma/anoma/$rev"); then
	url=$(<<<"$meta" jq -r .url)
	revHash=$(<<<"$meta" jq -r .revision)

	echo "Building from flake $url" >&2

	# Generate Cargo.nix, in case it is out-of-date
	rm -rf ./anoma
	url="github:anoma/anoma/$rev"
	nix flake clone "$url" --dest anoma
	env -C anoma nix run .#generateCargoNix

	nix-build "$THIS_SRC/image.nix" \
		--arg anoma 'builtins.getFlake (builtins.toString ./anoma)' \
		--argstr ANOMA_CHAIN_ID "$ANOMA_CHAIN_ID" \
		-o "$output"
else
	echo "No flake in $rev. Doing crate2nix instead" >&2

	# Fetch anoma source
	anomaJson=$(nix-prefetch-github anoma anoma --rev "${rev}")
	anomaSrc=$(nix-instantiate -E "(import <nixpkgs> {}).fetchFromGitHub (builtins.fromJSON ''$anomaJson'')")
	revHash=$(jq -r .rev <<<"$anomaJson")

	cargoNix=$(mktemp -p .)
	"$(nix-build '<nixpkgs>' -A crate2nix --no-out-link)/bin/crate2nix" generate \
		-f "$(nix-store -r "$anomaSrc")/Cargo.toml" \
		--no-default-features \
		--features "$ANOMA_FEATURES" \
		-o "$cargoNix"

	# Build
	nix-build "$THIS_SRC/image.nix" \
		--arg anomaSrc "$(nix-store -r "$anomaSrc")" \
		--arg cargoNix "$cargoNix" \
		--argstr ANOMA_FEATURES "$ANOMA_FEATURES" \
		--argstr ANOMA_CHAIN_ID "$ANOMA_CHAIN_ID" \
		-o "$output"
	rm "$cargoNix"
fi

if [[ -n $upload ]]; then
	if [[ -n $registry_auth ]]; then
		echo Setting up docker credentials >&2
		mkdir -p ~/.docker
		if [[ $registry = *docker.io ]]; then
			registry_index=https://index.docker.io/v2/
		else
			registry_index=$registry
		fi
		cat <<DOCKER_CONF > ~/.docker/config.json
	{ "auths": { "$registry_index": { "auth": "$(echo -n "$registry_auth" | base64)" } } }
DOCKER_CONF
	fi

	tag=${IMAGE_TAG:-"$(date +%F).${revHash::12}"}
	tag=$(echo -n "$tag" | tr -cs '[:alnum:]-._' '_')
	dst=docker://$registry/$repo:$tag

	echo "Copying image to $dst"

	skopeo=$(nix-build '<nixpkgs>' -A skopeo --no-out-link)/bin/skopeo

	./"$output" | gzip | "$skopeo" copy --insecure-policy docker-archive:/dev/stdin "$dst"
fi
