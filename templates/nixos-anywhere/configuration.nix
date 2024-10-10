{ inputs, ... }:
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
    # Example: root-disk.device = "/dev/sda";
  };

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    # Example: "ssh-ed25519 AAAA... nixos@dotfiles"
  ];

  system.stateVersion = "24.05";
}
