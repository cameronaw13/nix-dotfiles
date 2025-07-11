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
    #<<<<<<< EXAMPLE <<<<<<<
    root-disk.device = "/dev/sda";
    #>>>>> DO NOT KEEP >>>>>
  };

  networking = {
    #<<<<<<< EXAMPLE <<<<<<<
    hostName = "nixos";
    hostId = "01234567";
    #>>>>> DO NOT KEEP >>>>>
  };
}
