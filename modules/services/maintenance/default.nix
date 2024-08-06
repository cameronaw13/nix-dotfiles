{ lib, config, ... }:
{
  options.local.services.maintenance = {
    dates = lib.mkOption {
      type = lib.types.str;
    };
  };  
  
  imports = [
    ./wol.nix
    ./upgrade.nix
    ./garbage.nix
    ./optimise.nix
    #./snapshot.nix
    #./mail.nix
    ./poweroff.nix
  ];
}
