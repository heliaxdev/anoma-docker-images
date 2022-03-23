#!/usr/bin/env bash

set -euo pipefail

endpoint=https://api.github.com
owner=anoma
repo=anoma
maxAgeDays=14days

declare -A tagOverrides=(
	["v0.5.0"]="c0e2053fe1d9e93e9c25d45d67e07cbb5d081361" # samuli/v0.5.0/nix-build
)

maxAge=$(date +%s --date="$maxAgeDays ago")

# Anoma releases
curl -sSLf $endpoint/repos/$owner/$repo/releases | \
	jq -r  ".[] | select((.draft == false) and (.created_at | fromdate) > $maxAge) | .tag_name" \
	| tac >releases.tags

# Tags that exist on docker hub
skopeo list-tags docker://docker.io/heliaxdev/anoma | jq -r .Tags[] >dockerhub.tags

# Process all new tags
comm -31 <(sort dockerhub.tags) <(sort releases.tags) | while read -r tag
do
	rev=${tagOverrides["$tag"]:-"$tag"} || :
	echo "Processing tag $tag (rev=$rev)"
	nix run .\#build-and-publish-image -- --rev "$rev" --image-tag "$tag" "$@"
done
