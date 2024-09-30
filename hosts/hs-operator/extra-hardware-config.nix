{ lib, ... }:
let
  rootDisk = "/dev/sda";
in
{
  /*imports = [
    (import ./disko.nix { device = rootDisk; })
    inputs.disko.nixosModules.disko
  ];*/
  
  /* Boot */
  boot.loader.grub.enable = lib.mkDefault true;
  # boot.loader.grub.useOSProber = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = lib.mkDefault rootDisk; # or "nodev" for efi only
  # boot.supportedFileSystems = [ "zfs" ];
  # boot.zfs.forceImportRoot = false;
  /*boot.initrd.postDeviceCommands = lib.mkAfter ''
    zfs rollback -r zroot/root@blank
  '';*/

  /* Filesystems */
  /*filesystems = {
    # Accomodate for unmounted disks
    "/" = {
      device = "zroot/root";
      fsType = "zfs";
    };
    "/nix" = {
      device = "zroot/nix";
      fsType = "zfs";
    };
    "/persist" = {
      device = "zroot/persist";
      fsType = "zfs";
    };
  };*/

  /* Networking */
  networking = {
    useDHCP = false;
    hostName = "hs-operator";
  };
  # MACVTAP
  /*systemd.network = {
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
  };*/
  # TAP
  systemd.network = {
    enable = true;
    networks = {
      "20-lan" = {
        matchConfig.Name = [ "ens18" "hs-*" ];
        networkConfig = {
          Bridge = "br0";
        };
      };
      "20-lan-bridge" = {
        matchConfig.Name = "br0";
        networkConfig = {
          Address = "192.168.4.200/24";
          Gateway = "192.168.4.1";
          DNS = "9.9.9.9";
        };
        linkConfig.RequiredForOnline = "routable";
      };
    };
    netdevs."br0" = {
      netdevConfig = {
        Name = "br0";
        Kind = "bridge";
      };
    };
  };

  /* QEMU */
  services.qemuGuest.enable = true;
}
