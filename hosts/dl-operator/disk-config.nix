_:
{
  disko.devices = {
    disk = {
      root-disk1 = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # BIOS
              priority = 1;
            };
            swap = {
              size = "8G";
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
      root-disk2 = {
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
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
        mode = "mirror";
        options = {
          autotrim = "on";
        };
        rootFsOptions = {
          mountpoint = "none";
          canmount = "off";
          compression = "lz4";
          autotrim = "on";
          acltype = "posixacl";
          xattr = "sa";
          dnodesize = "auto";
          atime = "off";
          normalization = "formD";
        };
        datasets = {
          # Main filesystem
          "zroot/root" = {
            type = "zfs_fs";
            mountpoint = "/";
            options = {
              mountpoint = "legacy";
              canmount = "noauto";
            };
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^zroot/root@blank$' || zfs snapshot zroot/root@blank";
          };
          # Nix store - required on boot
          "zroot/nix" = {
            type = "zfs_fs";
            mountpoint = "/nix";
            options = {
              mountpoint = "legacy"; # TODO: Is this needed?
              canmount = "noauto";
            };
          };
          # Persistent directory
          "zroot/persist" = {
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
