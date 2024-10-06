#!/usr/bin/env bash

if [ "$UID" -lt 1000 ]; then
  echo "Do not run with a system account!"
  echo "Exiting..."
  sleep 1
  exit 1
fi

user_continue() {
  local choice
  while :; do
    read -rp "Do you wish to continue? $1 [y/N]; " choice
    case "$choice" in
      y|Y) return 0;;
      n|N|"") return 1;;
    esac
  done
}

echo "Welcome to the nixos-anywhere script!"
echo "You will need to perform a couple manual steps before running this script"
echo "These are listed under https://github.com/cameronaw13/nix-dotfiles"
echo "Please complete these before running the script!"
echo
echo "To reiterate, make sure you've audited the contents of this script before running!"
echo
echo "Note: It's recommended to run this within distrobox or your choice of container/virtualization"
echo "software to isolate the script from critical environments."
echo
user_continue "(else, exit)" || exit 2

# Check if nix exists
while ! nix --version; do
  read -rp "Cannot find nix installation. Would you like to automatically install nix? [y/N]: " nix_choice
  case "$nix_choice" in
    y|Y)
      # Install multi/single-user nix based on existance of systemd init directory
      [ -d /run/systemd/system ] && nix_option="--daemon" || nix_option="--no-daemon"
      echo "Installing nix in $nix_option mode"
      sh <(curl -L https://nixos.org/nix/install) "$nix_option"
      echo "Nix install completed!"
      ;;
    n|N|"")
      echo "Suspend the process (^Z) and visit 'https://nixos.org/download/' to manually install nix."
      echo "You can return to this script with the 'fg' command, see builtins(1)."
      echo
      user_continue "(else, exit)" || exit 2
      ;;
  esac
done
  
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
  user_continue "(else, repeat options)" && break
done;

# Variable setup
mkdir -p "$dir_choice"
mkdir -p "$HOME"/.ssh
yes '' | ssh-keygen -t ed25519 -C "$USER@$HOSTNAME" -f "$dir_choice"/temp-nixos
ssh-copy-id -i "$dir_choice"/temp-nixos "$addr_choice"

# Pull nixos-anywhere templates # TODO: Change branch to master when merged
wget -P "$dir_choice" -O "$dir_choice"/nix-dotfiles.zip https://github.com/cameronaw13/nix-dotfiles/archive/refs/heads/installation.zip
unzip -j "$dir_choice"/nix-dotfiles.zip "nix-dotfiles-installation/templates/nixos-anywhere/*" -d "$dir_choice"/templates

# Add ssh key to configuration.nix template
ssh_curr=$(( $(grep -n "users.users.root.openssh.authorizedKeys.keys" "$dir_choice"/templates/configuration.nix | cut -d: -f1) + 2 ))
sed -i "${ssh_curr}i \    $(cat "$dir_choice"/temp-nix.pub)" "$dir_choice"/templates/configuration.nix

# Pull disk-config.nix if hostname exists
hostname_dir="nix-dotfiles-installation/hosts/$hostname_choice"
if unzip -l "$dir_choice"/nix-dotfiles.zip | grep -q "$hostname_dir"; then
  unzip -j "$dir_choice"/nix-dotfiles.zip "$hostname_dir"/disk-config.nix -d "$dir_choice"/templates
  
  # Get list of defined disks from hostname
  disk_list="$(nix-instantiate --strict --eval --expr 'with import <nixpkgs> { };
  lib.attrsets.mapAttrsToList (name: value: name) (import '"$dir_choice"'/templates/disk-config.nix { }).disko.devices.disk' \
  | sed -r "s/^\[(.*)\]$/\1/g" | tr , ' ')"
  
  # Add disks into configuration.nix template
  disk_curr=$(( $(grep -n "disko.devices.disk" "$dir_choice"/templates/configuration.nix | cut -d: -f1) + 2 ))
  for disk in "${disk_list[@]}"; do
    sed -i "${disk_curr}i \    $disk.device = ...;" "$dir_choice"/templates/configuration.nix
    ((curr++))
  done
fi

# Obtain fdisk info from client
while :; do
  read -rp "Do you want to obtain block device information from $addr_choice? [y/N]: " block_choice
  case "$block_choice" in
    y|Y)
      ssh -i "$dir_choice"/temp-nixos "$addr_choice" -t "sudo fdisk -l"
      ;;
    n|N|"")
      break
      ;;
  esac
done

# User verification of nixos-anywhere templates
while :; do
  echo "Setup for nixos-anywhere is partially complete. Verification of the template files is needed"
  echo "Templates are located in $dir_choice/templates"
  echo "Make sure to define 'disko.devices.disk' in templates/configuration.nix based on the"
  echo "client's block device layout to properly boot nixos."
  echo "templates/disk-config.nix may still need an implementation based on your configuration."
  echo
  echo "Suspend the process (^Z) and cd into '$dir_choice/templates' to perform verification."
  echo "You can return to this script with the 'fg' command, see builtins(1)."
  echo
  user_continue "(else, exit)" || exit 2

  echo
  echo "Are you *completely* sure that everything is configured properly? EVERY hard drive on $hostname_choice will be COMPLETELY ERASED if improperly set up!"
  echo
  user_continue "(else, repeat verification)" && break
done


