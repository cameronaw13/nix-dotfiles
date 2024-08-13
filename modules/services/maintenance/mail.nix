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
    recipients = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = config.local.services.postfix.rootAliases;
    };
  };

  config = lib.mkIf (maintenance.mail.enable && config.local.services.postfix.enable) {
    systemd.services.auto-mail = {
      description = "NixOS maintenance mail service";
      serviceConfig.Type = "oneshot";
      startAt = maintenance.dates;

      script = let
        services = lib.strings.concatStringsSep " " config.systemd.services.auto-mail.after; 
        sendmail = "${pkgs.postfix}/bin/sendmail";
        sender = config.local.services.postfix.sender;
        receivers = lib.strings.concatStringsSep "," maintenance.mail.recipients;
      in ''
        serviceList=(${services})
        total=0
        success=0
        status="SUCCESS"
        truncate="]: deleting '"

        for i in "''${serviceList[@]}"; do
          logs="$(journalctl -u "$i" --no-pager -S "$(systemctl show auto-start.service | grep "ExecMainStartTimestamp=" | cut -d " " -f2-)")"
          
          contents+="$i " 
          if ! $(echo "$logs" | grep -qE "^-- No entries --$"); then
            if $(systemctl is-failed --quiet "$i"); then
              contents+="[failed]:"
              status="FAILURE"
            else
              contents+="[success]:"
              (( ++success ))
            fi
            (( ++total ))
          fi
          contents+=$'\n'"$(echo "$logs" | grep -C2 --group-separator="-- truncated $(( $(echo "$logs" | grep -c "$truncate") - 4 )) lines --" -v "$truncate")"$'\n\n'
        done

        cat <<EOF | ${sendmail} -f ${sender} -t ${receivers}
        Subject: Maintenance Job [$success/$total]: $status
        Content-Type: text/plain; charset="UTF-8"

        $contents
        EOF
      '';

      after = [
        "auto-wol.service"
        "auto-rebase.service"
        "nixos-upgrade.service"
        "nix-optimise.service"
        "nix-gc.service"
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
