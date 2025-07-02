{ lib, ... }:
{
  options.local.services.maintenance = {
    dates = lib.mkOption {
      type = lib.types.singleLineStr;
      description = "Maintence schedule startup time. Specified through systemd.time(7)";
      default = "Mon *-*-* 00:00:00";
    };
  };  
  
  imports = [
    ./start.nix
    ./wol.nix
    ./pull.nix
    ./upgrade.nix
    ./optimise.nix
    ./garbage.nix
    ./poweroff.nix
    ./mail.nix
  ];
}
