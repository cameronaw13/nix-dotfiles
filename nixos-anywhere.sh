#!/usr/bin/env bash

# Notes:
# 1) https://manpages.ubuntu.com/manpages/xenial/en/man3/sd_booted.3.html

user_continue() {
  read -rp "Do you wish to continue? [y/N]; " choice
  if [ "${choice,,}" != "y" ]; then
    echo "Exiting..."
    exit 2
  fi
}

if [ "$UID" -lt 1000 ]; then
  echo "Please do not run with a system account!"
  echo "Exiting..."
  exit 1
fi

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
    # Install multi/single-user nix dependant on systemd init [1]
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

# Generate flake.nix config
