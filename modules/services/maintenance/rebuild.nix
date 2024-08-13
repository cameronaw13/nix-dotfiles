{ lib, config, inputs, ... }:
let
  maintenance = config.local.services.maintenance;
in
{
  options.local.services.maintenance.nixosRebuild = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf maintenance.nixosRebuild.enable {
    system.autoUpgrade = {
      enable = lib.mkDefault true;
      dates = maintenance.dates;
      operation = "boot";
      flake = inputs.self.outPath;
      flags = [
        "-L" # print build logs
      ];
    };

    systemd.services.nixos-upgrade = {
      after = [ "auto-rebase.service" ];
    };
  };
}
