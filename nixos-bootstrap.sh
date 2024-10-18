#!/usr/bin/env bash

# Error handling
trap 'catch $? $LINENO' ERR
catch() {
  if [ "$1" != 0 ]; then
    echo "| Returned error code $1 on line $2" >&2
    echo "| Exiitng..." >&2
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
  echo "| This system does not appear to be running NixOS (nixos-version does not exit)"
  echo "| A running installation of NixOS is required!"
  echo "|"
  read -rn 1 -p "(Press any key to exit) "
  exit 1
fi

# Begin
echo "| Welcome to the nixos-boostrap script!"
echo "| This script will load and rebuild the nix-dotfiles repo onto a nixos system."
echo "| This script is ran as an extension of the 'nixos-anywhere.sh' script, please take note of any"
echo "| potential discrepancies when running separately!"
echo "|"
echo "| Make sure you've audited the contents of this script before running!"
echo "|"
user_continue "exit" && echo || exit 0

# Initial setup
#expfeats=(--experimental-features "nix-command flakes")
hostDir=/etc/nixos/hosts/"$HOSTNAME"
cd /etc/nixos

# Permission fixes
sudo chgrp -R wheel "$PWD"
sudo chmod -R g+s "$PWD"
sudo chmod -R u=rwX,g=rwX,o=rX "$PWD"
sudo setfacl -dRm g::rw "$PWD"

# Temp github ssh-key setup
if [ ! -f "$HOME"/.ssh/git-key ]; then
  ssh-keygen -t ed25519 -C "$USER@$HOSTNAME" -N "" -f "$HOME"/.ssh/git-key
fi
nix run nixpkgs#gh -- auth login -h github.com -p ssh --skip-ssh-key --scopes "admin:public_key,admin:ssh_signing_key"
#types=("authentication" "signing")
#for index in "${types[@]}"; do
#  nix run nixpkgs\#gh -- ssh-key add --type "$index" --title "$USER@$HOSTNAME" "$HOME"/.ssh/git-key.pub
#done
nix run nixpkgs#gh -- ssh-key add --title "$USER@$HOSTNAME" "$HOME"/.ssh/git-key.pub

# Git config setup
nix run nixpkgs#gitMinimal -- config --global --add core.sshCommand "ssh -i $HOME/.ssh/git-key"
nix run nixpkgs#gitMinimal -- config --global --add safe.directory "$PWD"

# Cloning nix-dotfiles repo
#if nix run nixpkgs\#gitMinimal -- ls-remote --heads git@github.com:cameronaw13/nix-dotfiles.git | grep "$HOSTNAME"; then
#  cloneFlags=(--branch "$HOSTNAME")
#fi
nix run nixpkgs#gitMinimal -- clone --recurse-submodules --remote-submodules --jobs=8 git@github.com:cameronaw13/nix-dotfiles.git "$PWD"
nix run nixpkgs#gitMinimal -- checkout -B "$HOSTNAME"
nix run nixpkgs\#gitMinimal -- pull origin "$HOSTNAME" || echo "New host branch '$HOSTNAME', no need to pull"
nix run nixpkgs#gitMinimal -- submodule foreach --recursive "git checkout master || true"

# If existing host, copy hardware-configuration.nix as well as "disko.devices.disk" and "networking.hostId" from configuration.nix to the new configuration
  # Else, copy all files under /nixos-anywhere/* to /etc/nixos/hosts/$hostname
  # Could also change nix min/max free based on root disk size
if [ -d "$hostdir" ]; then
  mv "$hostdir"/hardware-configuration.nix "$hostdir"/hardware-configuration.nix~
  cp /nixos-anywhere/hardware-configuration.nix "$hostdir"
else
  mkdir -p "$hostdir" 
  cp /nixos-anywhere/* "$hostdir"


# Allow user verification for new configuration (setup static networking, extra-hardware-config, etc)

# Generate host age key based on host ssh keys
  # If no age key is given to decrypt secrets, generate new secrets file

# Generate age keys for each declared user(?)
  # Could create a separate script that searches for each declared user with secrets support and both generates and enrolls an age key if needed 
  # NOTE: should separate bash scripts from nix code to ease debugging, may need to rethink how to declare bash scripts

# Rebuild and finish
