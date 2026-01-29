#!/usr/bin/env bash
# Merge shared and profile-specific YAML files using yq.
#
# Deep merges two YAML files:
# - Dicts are recursively merged
# - Lists are concatenated
# - Scalar conflicts will have profile values override shared values
#
# Usage: merge_yaml.sh <shared.yaml> <profile.yaml> <output.yaml>

set -euo pipefail

if [[ $# -ne 3 ]]; then
    echo "Usage: merge_yaml.sh <shared.yaml> <profile.yaml> <output.yaml>" >&2
    exit 1
fi

SHARED_YAML="$1"
PROFILE_YAML="$2"
OUTPUT_YAML="$3"

# Verify input files exist
if [[ ! -f "$SHARED_YAML" ]]; then
    echo "Error: Shared YAML file not found: $SHARED_YAML" >&2
    exit 1
fi

if [[ ! -f "$PROFILE_YAML" ]]; then
    echo "Error: Profile YAML file not found: $PROFILE_YAML" >&2
    exit 1
fi

# Verify yq is available
if ! command -v yq &> /dev/null; then
    echo "Error: yq is required but not installed. Run: brew install yq" >&2
    exit 1
fi

# Merge YAML files using yq
# The '*' operator deep merges, with later values taking precedence
# For arrays, we use '*+' to concatenate instead of replace
yq eval-all '
  . as $item ireduce ({}; . *+ $item)
' "$SHARED_YAML" "$PROFILE_YAML" > "$OUTPUT_YAML"

echo "Merged $SHARED_YAML + $PROFILE_YAML -> $OUTPUT_YAML"
