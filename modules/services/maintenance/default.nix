{ lib, config, ... }:
{
  options.local.services.maintenance = {
    dates = lib.mkOption {
      type = lib.types.str;
      description = "Maintence schedule startup time. Specified through systemd.time(7)";
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
