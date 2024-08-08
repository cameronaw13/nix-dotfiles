{ lib, config, pkgs, ... }:
let
  maintenance = config.local.services.maintenance;
in
{
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

      # TODO: Account for disabled services and failures
      # TODO: Improve log truncate system
      script = let
        services = lib.strings.concatStringsSep " " config.systemd.services.auto-mail.after; 
        sendmail = "${pkgs.postfix}/bin/sendmail";
        sender = config.local.services.postfix.sender;
        receiver = config.local.services.postfix.receiver;
        hostname = config.networking.hostName;
      in ''
        serviceList=(${services})

        # complete pita
        for i in "''${serviceList[@]}"; do
          contents+="$i:"$'\n' # prefix
          contents+="$(journalctl -u "$i" --no-pager -S "$(systemctl show auto-start.service | grep "ExecMainStartTimestamp=" | cut -d " " -f2-)" | grep -A3 -B3 -v "]: deleting '" || true )"
          contents+=$'\n\n' # suffix
        done

        cat <<EOF | ${sendmail} -f ${sender} -t ${receiver}
        Subject: ${hostname} maintenance job [14/14]: success
        Content-Type: text/plain; charset="UTF-8"

        $contents
        EOF
      '';

      after = [
        "auto-wol.service"
        "nixos-upgrade.service"
        "nix-gc.service"
        "nix-optimise.service"
        "auto-poweroff.service"
      ];
    };

    systemd.timers.auto-mail = {
      timerConfig = {
        Persistent = true;
        RandomizedDelaySec = "0";
      };
    };
  };
}
