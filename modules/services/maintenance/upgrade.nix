{ lib, config, inputs, pkgs, ... }:
let
  maintenance = config.local.services.maintenance;
  prev = "auto-wol.service";
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
    commit = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf maintenance.autoUpgrade.enable {
    system.autoUpgrade = {
      enable = true;
      dates = maintenance.dates;
      operation = "boot";
      flake = inputs.self.outPath;
      flags = [
        "-L" # print build logs
      ];
    };

    systemd.services.nixos-upgrade = {
      serviceConfig.WorkingDirectory = "/etc/nixos";
      
      # Separately update flake avoiding 'nixos-rebuild --update-input' deprecation
      preStart= let
        su = "${pkgs.su}/bin/su";
        user = maintenance.autoUpgrade.user;
        commit = toString maintenance.autoUpgrade.commit;
      in ''
        ${su} ${user} <<'EOF'
        if (( ${commit} )); then
          nix flake update --commit-lock-file
          git push
        else
          nix flake update
        fi
        EOF
      '';
      
      wants = lib.mkForce [ "network-online.target" prev ];
      after = lib.mkForce [ "network-online.target" prev ];
    };
  };
}
