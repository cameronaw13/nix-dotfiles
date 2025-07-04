#!/usr/bin/env bash
set -x
type -P git >/dev/null \
  && git="git" \
  || git=(nix run nixpkgs\#gitMinimal -- )

tabs 4
toplevel="$("${git[@]}" rev-parse --show-toplevel)"
if [ "$toplevel" != "$SCRIPT_PATH" ]; then
  echo "Please run within the '$SCRIPT_PATH' directory"
  exit 1
fi
base="master"
head="$HOSTNAME"
read -rp "PR Title: " title
body="$("${git[@]}" log origin/master..HEAD --reverse --format=%s$'\n```\n'%b$'\n```')"
fmtbody="$(sed 's/^/\t/g' <<< "$body")"

printf "\nBase: %s" "$base"
printf "\nHead: %s" "$head"
printf "\nTitle: %s" "$title"
printf "\nBody:\n%s\n\n" "$fmtbody"

read -rp "Do you wish to continue? (y/N): " choice
case "$choice" in
  y|Y) gh pr create --base "$base" --head "$head" --title "$title" --body "$body";;
esac
exit 0
