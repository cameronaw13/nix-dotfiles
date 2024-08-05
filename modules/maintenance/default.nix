{ lib, config, ... }:
{
  options.local.maintenance = {
    dates = lib.mkOption {
      type = lib.types.str;
    };
  };  
  
  imports = [
    ./autoUpgrade.nix
    ./nix-gc.nix
    ./nix-optimise.nix
    #./reboot.nix
    #./snapshot.nix
  ];
}
