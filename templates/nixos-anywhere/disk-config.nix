{ ... }:
# A Hybrid setup, more examples shown below: 
# https://github.com/nix-community/disko/blob/master/example
# https://github.com/nix-community/disko-templates
{
  disko.devices = {
    disk = {
      root-disk = {
        type = "disk";
        content = {
          type = "gpt";
          partition = {
            boot = {
              size = "1M";
              type = "EF02"; # BIOS
              priority = 1;
            };
            ESP = {
              size = "512M";
              type = "EF00"; # UEFI
              content = {
                type = "filesystem";
                format = "vfat";
                mountpont = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
