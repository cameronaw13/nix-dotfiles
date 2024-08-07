{ lib, config, pkgs, ... }:
let
  maintenance = config.local.services.maintenance;
  prev = "auto-poweroff.service";
in {
  options.local.services.maintenance.mail = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = config.local.services.postfix.enable;
    };
  };

  config = lib.mkIf (maintenance.mail.enable && config.local.services.postfix.enable) {
    systemd.services.auto-mail = {
      description = "NixOS maintenance mail service";
      serviceConfig.Type = "oneshot";
      startAt = maintenance.dates;

      # TODO: Account for disable services and failures
      # TODO: Improve log truncate system
      script = let
        services = lib.strings.concatStringsSep " " [
          "auto-wol.service"
          "nixos-upgrade.service"
          "nix-gc.service"
          "nix-optimise.service"
          "auto-poweroff.service"
        ];
        sendmail = "${pkgs.postfix}/bin/sendmail";
        hostname = config.networking.hostName;
        sender = config.local.services.postfix.sender;
        receiver = config.local.services.postfix.receiver;
      in ''
        serviceList=(${services})

        # complete pita
        for i in "''${serviceList[@]}"; do
          contents+="$i:"$'\n' # prefix
          contents+="$(journalctl -u "$i" --no-pager -S "$(systemctl show "$i" | grep "ExecMainStartTimestamp=" | cut -d " " -f2-)" | grep -v -A 5 "]: deleting '")"
          contents+=$'\n\n' # suffix
        done

        cat <<EOF | ${sendmail} -f ${sender} -t ${receiver}
        Subject: Maintenance Completed!
        Content-Type: text/plain; charset="UTF-8"

        $contents
        EOF
      '';

      wants = [ prev ];
      after = [ prev ];
    };

    systemd.timers.auto-mail = {
      timerConfig = {
        Persistent = true;
        RandomizedDelaySec = "0";
      };
    };
  };
}
