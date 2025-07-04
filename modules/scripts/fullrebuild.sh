#!/usr/bin/env bash
set -x
type -P git >/dev/null \
  && git="git" \
  || git=(nix run nixpkgs\#gitMinimal -- )

toplevel=$("${git[@]}" rev-parse --show-toplevel)
if [ "$toplevel" != "$SCRIPT_PATH" ]; then
  echo "Please run within '$SCRIPT_PATH' directory"
  exit 1
fi
if [ -z "$1" ]; then
  echo "No operation specified. Refer to nixos-rebuild(8)"
  exit 1
fi

echo "-- Rebase --"
"${git[@]}" fetch -v
"${git[@]}" stash -u
"${git[@]}" rebase origin/master
status=$?
if [ -n "$("${git[@]}" stash list)" ]; then
  "${git[@]}" stash pop -q
  status=$(( status || $? ))
fi
if (( status )); then
  echo "Rebase conflicts found. Manual intervention needed."
  exit 1
fi
"${git[@]}" push --force-with-lease origin "$HOSTNAME"

echo "-- Rebuild --"
"${git[@]}" add -Av
if ! sudo nixos-rebuild "$1" --option eval-cache false; then
  echo "'nixos-rebuild $1' failed, exiting..."
  exit 1
fi

echo "-- Commit --"
message=$("${git[@]}" diff --cached --numstat)
if [ "$message" = "" ]; then
  echo "no changes found, skipping commit..."
  exit 0
fi
"${git[@]}" commit -m "nixos-rebuild: $1" -m "added   deleted"$'\n'"$message"
"${git[@]}" push origin "$HOSTNAME"
