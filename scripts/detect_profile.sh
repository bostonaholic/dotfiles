#!/usr/bin/env bash
set -euo pipefail

PROFILE_FILE="$HOME/.dotfiles_profile"

if [[ -f "$PROFILE_FILE" ]]; then
  PROFILE=$(cat "$PROFILE_FILE")
  if [[ "$PROFILE" == "work" || "$PROFILE" == "personal" ]]; then
    echo "$PROFILE"
    exit 0
  fi
  # Invalid profile stored, fall through to prompt
  echo "Invalid profile '$PROFILE' in $PROFILE_FILE, re-prompting..." >&2
fi

# Prompt for profile selection
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
