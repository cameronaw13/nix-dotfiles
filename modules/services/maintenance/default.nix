{ lib, config, ... }:
{
  options.local.services.maintenance = {
    dates = lib.mkOption {
      type = lib.types.singleLineStr;
      description = "Maintence schedule startup time. Specified through systemd.time(7)";
    };
  };  
  
  imports = [
    ./start.nix
    ./wol.nix
    ./upgrade.nix
    ./garbage.nix
    ./optimise.nix
    #./snapshot.nix
    ./poweroff.nix
    ./mail.nix
  ];
}
