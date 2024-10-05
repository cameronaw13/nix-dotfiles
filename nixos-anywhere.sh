#!/usr/bin/env bash

# Script setup
set -e
if [ "$UID" -lt 1000 ]; then
  echo "Please do not run with a system account!"
  echo "Exiting..."
  exit 1
fi

user_continue() {
  read -rp "Do you wish to continue? [y/N]; " choice
  if [ "${choice,,}" != "y" ]; then
    echo "Exiting..."
    exit 2
  fi
}

echo "Welcome to the nixos-anywhere script!"
echo "You will need to perform a couple manual steps before running this script"
echo "These are listed under https://github.com/cameronaw13/nix-dotfiles"
echo "Please complete these before running the script!"
echo
echo "To reiterate, make sure you've audited all code ran with this script before running!"
echo "Its recommended to run this within distrobox or some other container/virtualization layer"
echo "to isolate the script from any critical environments."
echo
user_continue

# Check if nix exists
while ! nix --version; do
  read -rp "It seems that nix isn't installed! Would you like to install nix? [y/N]: " nix_choice
  if [ "${nix_choice,,}" = "y" ]; then
    # Install multi/single-user nix dependant on systemd init location
    ls /run/systemd/system && nix_option="--daemon" || nix_option="--no-daemon"
    echo "Installing nix in $nix_option mode"
    sh <(curl -L https://nixos.org/nix/install) "$nix_option"
    echo "Finished installing nix!"
  else
    echo "Suspend the process (^Z) and visit 'https://nixos.org/download/' to manually install nix"
    echo "You can return with the 'fg' command, see builtins(1)"
    echo
    user_continue
  fi
done

# TODO: Add confirmation page before mkdir/ssh-keygen for user variables
# Set template directory
read -rp "Choose a directory to store the nixos-anywhere templates: " dir_choice
dir_choice="$(echo "$dir_choice" | sed -r "s@~@$HOME@g")"
mkdir -p "$dir_choice"

# Set client ssh access
read -rp "Enter the user@ip_addr of the machine nixos will be installed on: " addr_choice
mkdir -p "$HOME"/.ssh
yes '' | ssh-keygen -t ed25519 -C "${USER}@${HOSTNAME}" -f "$dir_choice"/temp-nix
ssh-copy-id -i "$dir_choice"/temp-nix "$addr_choice" # TODO: Is this necessary?

# Set hostname
read -rp "Enter the desired hostname for the client machine: " hostname_choice

# TODO: Add echo output for each section for readibility in case of error
# Pull nixos-anywhere template # NOTE: Change branch to master when merged
zip_file="$dir_choice"/nix-dotfiles.zip
template_dir="nix-dotfiles-installation/templates/nixos-anywhere/*"
wget -P "$dir_choice" -O "$zip_file" https://github.com/cameronaw13/nix-dotfiles/archive/refs/heads/installation.zip
unzip -j "$zip_file" "$template_dir" -d "$dir_choice"/nixos-anywhere

# Pull/create disk-config.nix
hostname_dir="nix-dotfiles-installation/hosts/${hostname_choice}"
if unzip -l "$zip_file" | grep -q "$hostname_dir"; then
  unzip -j "$zip_file" "$hostname_dir"/disk-config.nix -d "$dir_choice"/nixos-anywhere

  # Insert list of defined disks from hostname's disk-config.nix
  disk_list="$(nix-instantiate --strict --eval --expr 'with import <nixpkgs> { };
  lib.attrsets.mapAttrsToList (name: value: name) (import '"${dir_choice}"'/nixos-anywhere/disk-config.nix { }).disko.devices.disk' \
  | sed -r "s/^\[(.*)\]$/\1/g" | tr , ' ')"
  
  curr=$(( $(grep -n "disko.devices.disk" "$dir_choice"/nixos-anywhere/configuration.nix | cut -d: -f1) + 2 ))
  for disk in "${disk_list[@]}"; do
    sed -i "${curr}i \    ${disk}.device = ...;" "${dir_choice}"/nixos-anywhere/configuration.nix
    ((curr++))
  done
fi
