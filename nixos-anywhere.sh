#!/usr/bin/env bash

# Error handling
trap 'catch $? $LINENO' ERR
catch() {
  if [ "$1" != 0 ]; then
    echo "Returned error code $1 on line $2" >&2
    echo "Exiting..." >&2
  fi
  exit "$1"
}

# Continue dialog
user_continue() {
  local choice
  while :; do
    read -rp "Press [y|Y] to continue, [n|N] to $1: " choice
    case "$choice" in
      y|Y) return 0;;
      n|N) return 1;;
    esac
  done
}

# Privilege de-escalation
if [ "$(id -u)" -lt 1000 ]; then
  echo "Do not run with a system account!" >&2
  echo "Exiting..." >&2
  exit 126
fi

# Begin
echo "Welcome to the nixos-anywhere script!"
echo "You will need to perform a couple manual steps before running this script"
echo "These are listed under https://github.com/cameronaw13/nix-dotfiles"
echo "Please complete these before running the script!"
echo
echo "Make sure you've audited the contents of this script before running!"
echo
echo "Note: It's recommended to run this within distrobox or your choice of container/virtualization"
echo "software to isolate the script from critical environments."
echo
user_continue "exit" && echo || exit 0

# Check if nix exists
if ! command -v nix; then
  echo "Cannot find nix installation. Nix will be automatically installed"
  user_continue "exit" && echo || exit 0

  # Install multi/single-user nix based on existance of systemd init directory
  [ -d /run/systemd/system ] && nix_option="--daemon" || nix_option="--no-daemon"
  echo "Installing nix in '$nix_option' mode"
  sh <(curl -L https://nixos.org/nix/install) "$nix_option"
  echo "Nix install completed!"

  echo "Restart your shell (eg: 'exec \$SHELL') and restart this script to continue"
  read -rsn 1 -p "(Press any key to exit...)"
  echo
  exit 129
fi
  
# Set options
while :; do
  read -rp "Set a directory to store nixos-anywhere templates: " dir_choice
  read -rp "Enter the user@ip_addr of the machine to install nixos on: " addr_choice
  read -rp "Enter desired hostname for the client machine: " hostname_choice
  dir_choice="$(echo "$dir_choice" | sed -r "s@~@$HOME@g")"

  echo
  echo "Template Directory: '$dir_choice'"
  echo "Client SSH Address: '$addr_choice'"
  echo "Client Hostname: '$hostname_choice'"
  echo
  user_continue "repeat verification" && echo && break
done

# Variable setup
mkdir -p "$dir_choice"
mkdir -p "$HOME"/.ssh
yes '' | ssh-keygen -t ed25519 -C "$USER@$HOSTNAME" -f "$dir_choice"/client-key
ssh-copy-id -i "$dir_choice"/client-key "$addr_choice"

# Pull nixos-anywhere templates # TODO: Change branch to master when merged
wget -P "$dir_choice" -O "$dir_choice"/nix-dotfiles.zip https://github.com/cameronaw13/nix-dotfiles/archive/refs/heads/installation.zip
unzip -Bj "$dir_choice"/nix-dotfiles.zip "nix-dotfiles-installation/templates/nixos-anywhere/*" -d "$dir_choice"/templates

# Add ssh key to configuration.nix template
ssh_curr=$(( $(grep -n "users.users.root.openssh.authorizedKeys.keys" "$dir_choice"/templates/configuration.nix | cut -d: -f1) + 2 ))
sed -i "${ssh_curr}i \    $(cat "$dir_choice"/client-key.pub)" "$dir_choice"/templates/configuration.nix

# Pull disk-config.nix if hostname exists
hostname_dir="nix-dotfiles-installation/hosts/$hostname_choice"
if unzip -l "$dir_choice"/nix-dotfiles.zip | grep -q "$hostname_dir"; then
  unzip -Bj "$dir_choice"/nix-dotfiles.zip "$hostname_dir"/disk-config.nix -d "$dir_choice"/templates
  
  # Get list of defined disks from hostname
  IFS=" " read -ra disk_list <<< "$(nix-instantiate --strict --eval --expr 'with import <nixpkgs> { };
  lib.strings.concatStringsSep " " (lib.attrsets.mapAttrsToList (name: value: name) (
    import '"$dir_choice"'/templates/disk-config.nix { }
  ).disko.devices.disk)' | tr -d '"')"
  
  # Add disks into configuration.nix template
  disk_curr=$(( $(grep -n "disko.devices.disk" "$dir_choice"/templates/configuration.nix | cut -d: -f1) + 2 ))
  for disk in "${disk_list[@]}"; do
    sed -i "${disk_curr}i \    $disk.device = ...;" "$dir_choice"/templates/configuration.nix
    ((disk_curr++))
  done
fi
echo

# Add hostname to configuration.nix template
hostname_curr=$(grep -n "services.openssh.enable" "$dir_choice"/templates/configuration.nix | cut -d: -f1)
sed -i "${hostname_curr}i \  networking.hostName = \""$hostname_choice"\";" "$dir_choice"/templates/configuration.nix

# Obtain fdisk info from client
while :; do
  echo "Do you want to obtain block device information rom '$addr_choice'?"
  read -rp "(Knowing each block device location on the client is needed to complete installation) [y/N]: " block_choice
  echo
  case "$block_choice" in
    y|Y)
      ssh -i "$dir_choice"/client-key "$addr_choice" -t "sudo fdisk -l"
      echo
      echo "Block device information retrieved!"
      echo
      user_continue "exit" && echo || exit 0
      break
      ;;
    n|N|"")
      break
      ;;
  esac
done

# User verification of nixos-anywhere templates
while :; do
  echo "Setup for nixos-anywhere is partially complete. You still need to verify the template files!"
  echo "Make sure to define 'disko.devices.disk' in templates/configuration.nix based on the"
  echo "client's block device layout to properly boot nixos."
  echo "templates/disk-config.nix may still need an implementation based on your configuration."
  echo
  echo "Suspend the process (Ctrl+Z) and cd into '$dir_choice/templates' to perform verification."
  echo "You can return to this script with the 'fg' command, see builtins(1)."
  echo
  user_continue "exit" && echo || exit 0

  echo "Are you *completely* sure that everything is configured properly? ALL disks on"
  echo "'$hostname_choice' will be COMPLETELY ERASED if improperly set up!"
  echo
  user_continue "repeat verification" && echo && break
done

# Nixos-Anywhere
nix run --experimental-features "nix-command flakes" \
  github:nix-community/nixos-anywhere -- \
  --print-build-logs \
  --generate-hardware-config ./hardware-configuration.nix \
  --flake "$dir_choice"/templates#nixos-client \
  -i "$dir_choice"/client-key \
  "$addr_choice"
