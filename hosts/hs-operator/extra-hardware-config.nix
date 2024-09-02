{ lib, ... }:
{
  /* Bootloader */
  boot.loader.grub.enable = lib.mkDefault true;
  # boot.loader.grub.useOSProber = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = lib.mkDefault "/dev/sda"; # or "nodev" for efi only

  /* Networking */
  systemd.network = {
    enable = true;
    networks."50-ens18" = {
      matchConfig.Name = "ens18";
      address = [ "192.168.4.200/24" ];
      gateway = [ "192.168.4.1" ];
      dns = [ "9.9.9.9" ];
    };
    links."50-ens18" = {
      matchConfig.OriginalName = "ens18";
      linkConfig.WakeOnLan = "magic";
    };
  };
  networking = {
    useDHCP = false;
    hostName = "hs-operator";
  };
}
