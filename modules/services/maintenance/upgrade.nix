{ lib, config, inputs, pkgs, ... }:
let
  prev = "wakeOnLan.service";
in
{
  options.local.services.maintenance.autoUpgrade = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    user = lib.mkOption {
      type = lib.types.singleLineStr;
    };
  };

  config = lib.mkIf config.local.services.maintenance.autoUpgrade.enable {
    system.autoUpgrade = {
      enable = true;
      dates = config.local.services.maintenance.dates;
      operation = "boot";
      flake = inputs.self.outPath;
      flags = [
        "-L" # print build logs
      ];
    };

    systemd.services.nixos-upgrade = {
      # separately update flake avoiding --update-input deprecation
      preStart = let
        su = "${pkgs.su}/bin/su";
        user = config.local.services.maintenance.autoUpgrade.user;
      in ''
        ${su} ${user} -c "nix flake update -L"
      '';
      serviceConfig.WorkingDirectory = "/etc/nixos";

      wants = lib.mkForce [ "network-online.target" prev ];
      after = lib.mkForce [ "network-online.target" prev ];
    };
  };
}
