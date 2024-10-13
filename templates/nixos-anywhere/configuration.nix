{ lib, inputs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
  disko.devices.disk = {
    # eg: root-disk.device = "/dev/sda";
  };

  # eg: networking.hostName = "nixos";
  # eg: networking.hostId = "12345678";
  services.openssh.enable = true;

  users.users.bootstrap = {
    isNormalUser = true;
    description = "bootstrap"; 
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      # eg: "ssh-ed25519 AAAA... nixos@dotfiles"
    ];
  };

  # Allow sudo without password (Only for bootstrap, do not keep!)
  security.sudo.extraRules = lib.mkAfter [ {
    users = [ "bootstrap" ];
    commands = [ {
      command = "ALL";
      options = [ "NOPASSWD" "SETENV" ];
    } ];
  } ];

  system.stateVersion = "24.05";
}
