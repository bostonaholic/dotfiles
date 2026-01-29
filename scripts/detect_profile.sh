#!/usr/bin/env bash
set -euo pipefail

PROFILE_FILE="$HOME/.dotfiles_profile"

if [[ -f "$PROFILE_FILE" ]]; then
  PROFILE=$(cat "$PROFILE_FILE")
  echo "$PROFILE"
else
  echo "Is this a work or personal machine?" >&2
  select profile in "work" "personal"; do
    case $profile in
      work|personal)
        echo "$profile" > "$PROFILE_FILE"
        echo "$profile"
        break
        ;;
      *)
        echo "Please select 1 (work) or 2 (personal)" >&2
        ;;
    esac
  done
fi
