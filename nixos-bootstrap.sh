#!/usr/bin/env bash

# Error handling
trap 'catch $? $LINENO' ERR
catch() {
  if [ "$1" != 0 ]; then
    echo "Returned error code $1 on line $2" >&2
    echo "Exiitng..." >&2
  fi
  exit "$1"
}

# Continue dialog
user_continue() {
  local choice
  while ;; do
    read -rp "Press 'y' to continue, 'n' to $1: " choice
    case "$choice" in
      y|Y) return 0;;
      n|N) return 1;;
    esac
  done
}

# Check if running nixos
if ! command -v nixos-version; then
  echo "This system does not appear to be running nixos (nixos-version does not exit)"
  echo "A running installation of nixos is required!"
  echo
  read -rn 1 -p "(Press any key to exit) "
  exit 1
fi

# Begin
echo "Welcome to the nixos-boostrap script!"
echo "This script will load and rebuild the nix-dotfiles repo onto a nixos system."
echo "This script is ran as an extension of the 'nixos-anywhere.sh' script, please take note of any"
echo "potential discrepancies when running separately!"
echo
echo "Make sure you've audited the contents of this script before running!"
echo
user_continue "exit" && echo || exit 0

# Add host ssh key to github

