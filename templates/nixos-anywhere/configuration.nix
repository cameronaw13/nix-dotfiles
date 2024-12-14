{ lib, inputs, pkgs, ... }:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
    kernel.sysctl."kernel.sysrq" = 1;
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
  };
  disko.devices.disk = {
    # eg: root-disk.device = "/dev/sda";
  };

  networking = {
    # eg: networking.hostName = "nixos";
    #     networking.hostId = "01234567";
  };

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

  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
    gitMinimal
    gh
    ;
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "24.11";
}
