{ inputs, ... }:
{
  imports = [
    ./disk-config.nix
    inputs.disko.nixosModules.disko
  ];
  
  /* Boot */
  boot = {
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
    loader.grub = {
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
    /*initrd.postDeviceCommands = lib.mkAfter ''
      zfs rollback -r zroot/root@blank
    '';*/
  };

  /* Disko */
  disko.devices.disk = {
    root-disk1.device = "/dev/sda";
    root-disk2.device = "/dev/sdb";
  };

  /* Networking */
  networking = {
    hostName = "dl-operator";
    hostId = "bceeaabf";
    useDHCP = false;
  };
  # MACVTAP
  systemd.network = {
    enable = true;
    networks."50-enp4s0" = {
      matchConfig.Name = "enp4s0";
      networkConfig = {
        Address = "192.168.4.254/24";
        Gateway = "192.168.4.1";
        DNS = "9.9.9.9";
      };
    };
    links."50-enp4s0" = {
      matchConfig.OriginalName = "enp4s0";
      linkConfig.WakeOnLan = "magic";
    };
  };
  # TAP
  /*systemd.network = {
    enable = true;
    networks = {
      "20-lan" = {
        matchConfig.Name = [ "enp4s0" "dl-*" ];
        networkConfig = {
          Bridge = "br0";
        };
      };
      "20-lan-bridge" = {
        matchConfig.Name = "br0";
        networkConfig = {
          Address = "192.168.4.254/24";
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
  };*/
}
