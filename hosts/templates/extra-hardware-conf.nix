{ inputs, ... }:
{
  imports = [
    ./disk-config.nix
    inputs.disko.nixosModules.disko
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

  networking = {
    # eg: hostName = "nixos";
    #     hostId = "01234567";
  };
}
