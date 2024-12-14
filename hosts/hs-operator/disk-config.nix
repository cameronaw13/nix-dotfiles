_:
{
  disko.devices = {
    disk = {
      root-disk = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            BIOS = {
              size = "1M";
              type = "EF02"; # BIOS
              priority = 1;
            };
            ESP = {
              size = "512M"; 
              type = "EF00"; # EFI
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            swap = {
              size = "2G";
              content = {
                type = "swap";
                discardPolicy = "both";
                resumeDevice = true;
              };
            };
            root = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
    };
    zpool = {
      zroot = {
        type = "zpool";
        options = {
          autotrim = "on";
        };
        rootFsOptions = {
          mountpoint = "none";
          canmount = "off";
          compression = "lz4";
          acltype = "posixacl";
          xattr = "sa";
          dnodesize = "auto";
          atime = "off";
          normalization = "formD";
        };
        datasets = {
          # Main filesystem
          "root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              mountpoint = "legacy";
              canmount = "noauto";
            };
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot/root@blank$' || zfs snapshot zroot/root@blank";
          };
          # Nix store - required on boot
          "nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              mountpoint = "legacy";
              canmount = "noauto";
            };
          };
          # Persistent directory
          "persist" = {
            type = "zfs_fs";
            mountpoint = "/persist";
            options = {
              mountpoint = "legacy";
              canmount = "noauto";
            };
          };
        };
      };
    };
  };
}
