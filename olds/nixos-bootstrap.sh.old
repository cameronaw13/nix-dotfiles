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
echo "| changes you may need to make if running separately!"
echo "|"
echo "| Make sure you've audited the contents of this script before running!"
echo "|"
user_continue "exit" && echo || exit 0

# Variable setup
expfeats=(--experimental-features "nix-command flakes")
command -v gh && gh="gh" || gh=(nix run nixpkgs\#gh "${expfeats[@]}" --)
command -v git && git="git" || git=(nix run nixpkgs\#gitMinimal "${expfeats[@]}" --)

# Config directory setup
cd /etc/nixos
sudo chgrp -R wheel "$PWD"
sudo chmod -R g+s "$PWD"
sudo chmod -R u=rwX,g=rwX,o=rX "$PWD"
sudo setfacl -R --default --modify g::rw "$PWD"

# Temp github ssh-key setup
if [ ! -f "$HOME"/.ssh/git-key ]; then
  ssh-keygen -t ed25519 -C "$USER@$HOSTNAME" -N "" -f "$HOME"/.ssh/git-key
fi
"${gh[@]}" auth login --hostname github.com --protocol ssh --skip-ssh-key --scopes "admin:public_key,admin:ssh_signing_key"
"${gh[@]}" ssh-key add --title="$USER@$HOSTNAME" "$HOME"/.ssh/git-key.pub

# Git config setup
"${git[@]}" config --global --add core.sshCommand "ssh -i $HOME/.ssh/git-key"
"${git[@]}" config --global --add safe.directory "$PWD"

# Clone full nix-dotfiles repo
"${git[@]}" clone --recurse-submodules --remote-submodules --jobs=8 git@github.com:cameronaw13/nix-dotfiles.git "$PWD"
"${git[@]}" checkout -B "$HOSTNAME"
"${git[@]}" pull origin "$HOSTNAME" || echo "New host branch '$HOSTNAME', no need to pull"
"${git[@]}" submodule foreach --recursive "git checkout master || true"

# If existing host, copy hardware-configuration.nix as well as "disko.devices.disk" and "networking.hostId" from configuration.nix to the new configuration
  # Else, copy all files under /nixos-anywhere/* to /etc/nixos/hosts/$hostname
  # Could also change nix min/max free based on root disk size

# Copy necessary config to nix-dotfiles
host_dir=/etc/nixos/hosts/"$HOSTNAME"
if [ -d "$host_dir" ]; then
  # TODO: Use nix-editor to add disko.devices.disk, networking.hostId, etc
  cp --backup=numbered /nixos-anywhere/hardware-configuration.nix "$host_dir"
else
  # TODO: Replace configuration.nix with bootstrap configuration.nix template using nix-editor to add important configurations from anywhere configuration.nix template (disko.devices.disk, networking.hostId, etc)
  # also add extra-hardware-configuration.nix template and microvm templates (if necessary)
  mkdir -p "$host_dir" 
  templates=($(find /nixos-anywhere/* ! -name "*~*" ! -name "flake.*"))
  cp --backup=numbered -t "$host_dir" "${templates[@]}"
fi

# TODO: change networking interface and other extra-hardware-config options using dialogs and nix-editor

# TODO: Allow user verification for new configuration

# TODO: Generate host age key based on host ssh keys
  # If no age key is given to decrypt secrets, generate new secrets file

# TODO: Generate age keys for each declared user
  # utilize system.activationScripts to generate each user's sops key within their home dir (user directories will be created despite sops keys missing) and regenerate the secrets repo with each user's sops keys
  # TODO: will need to move bash scripts outside of nix files for readability, can use substitutions to insert nix options into script if needed (https://nixos.org/manual/nixpkgs/stable/#ssec-stdenv-functions)
  # In case home dir's aren't created before setup or if key setup is required before the rebuild process, use this command below:
    # nix-instantiate --strict --eval --expr 'with import <nixpkgs> { }; lib.strings.concatStringsSep " " (lib.attrsets.mapAttrsToList (name: value: name) (import ./configuration.nix { lib = "_"; pkgs = "_"; inputs = "_"; }).local.users)'

# TODO: Rebuild and finish
  # Will need to nixos-rebuild ___ w/out sudo first for nixos to find user-level ssh keys to access github
  # After it inevitably errors, then perform sudo nixos-rebuild ___
