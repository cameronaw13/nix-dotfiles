{ lib, config, inputs, pkgs, ... }:
let
  maintenance = config.local.services.maintenance;
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
      script = let
        su = "${pkgs.su}/bin/su";
        user = maintenance.autoUpgrade.user;
        commit = toString maintenance.autoUpgrade.commit;
        nixos-rebuild = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
        autoUpgrade = config.system.autoUpgrade;
      in ''
        ${su} ${user} <<'EOF'
        if (( ${commit} )); then
          nix flake update --commit-lock-file
          git push
        else
          nix flake update
        fi
        EOF

        ${nixos-rebuild} ${autoUpgrade.operation} ${toString autoUpgrade.flags}
      '';
      
      after = [ "auto-wol.service" ];
    };
  };
}
