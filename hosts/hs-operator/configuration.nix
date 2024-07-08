# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

# TODO: Create install, rebuild, flake, home-manager scripts for config management
# View rebuild errors:
# sudo bash -c "nixos-rebuild switch &>/etc/nixos/nixos-switch.log || (cat /etc/nixos/nixos-switch.log | grep --color -e \"error\" -e \" at \" && exit 1)"

{ pkgs, ... }:
{
  imports = [ 
    ./hardware-configuration.nix
    ../../modules/nixos/common.nix
    ../../modules/nixos/maintenance.nix
    ../../modules/nixos/users/default.nix
    ../../modules/nixos/services/default.nix
  ];

  /* Bootloader */
  # dependent on hardware bios, move to hardware-config?
  boot.loader.grub.enable = true;
  # boot.loader.grub.useOSProber = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only

  /* Virtual Console */
  console = {
    earlySetup = true;
    #font = "";
    keyMap = "us";
  };

  /* Networking */
  networking.hostName = "hs-operator";
  networking.networkmanager.enable = true;

  networking.useDHCP = false;
  networking.defaultGateway = "192.168.4.1";
  networking.nameservers = [ "9.9.9.9" ];
  # dependent on hardware's network interfaces, move to hardware-config?
  networking.interfaces.ens18 = {
    wakeOnLan.enable = true;
    ipv4.addresses = [ {
      address = "192.168.4.200";
      prefixLength = 24;
    } ];
  };
  
  /* System Packages */
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    # Host-specific system packages
  ];

  /* Users */
  cameron-user.enable = true;

  /* Services */
  # ...

  /* System */
  # Account for breaking changes before updating!
  system.stateVersion = "24.05";
}
