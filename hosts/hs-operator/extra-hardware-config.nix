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
  networking = {
    useDHCP = false;
    hostName = "hs-operator";
  };
  systemd.network = {
    enable = true;
    networks."50-ens18" = {
      matchConfig.Name = "ens18";
      networkConfig = {
        Address = "192.168.4.200/24";
        Gateway = "192.168.4.1";
        DNS = "9.9.9.9";
      };
    };
    links."50-ens18" = {
      matchConfig.OriginalName = "ens18";
      linkConfig.WakeOnLan = "magic";
    };
  };

  /* QEMU */
  services.qemuGuest.enable = true;
}
