#!/usr/bin/env bash

set -euo pipefail

endpoint=https://api.github.com
owner=anoma
repo=anoma

maxAge=$(date +%s --date=5days\ ago)

# Anoma releases
curl -sSLf $endpoint/repos/$owner/$repo/releases | \
	jq -r  ".[] | select((.draft == false) and (.created_at | fromdate) > $maxAge) | .tag_name" \
	| tac >releases.tags

# Tags that exist on docker hub
skopeo list-tags docker://docker.io/heliaxdev/anoma | jq -r .Tags[] >dockerhub.tags

# Process all new tags
comm -31 <(sort dockerhub.tags) <(sort releases.tags) | while read -r tag
do
	echo "Processing tag $tag"
	ANOMA_REV=$tag IMAGE_TAG=$tag nix run .#build-and-publish-image
done
