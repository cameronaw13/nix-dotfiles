{ lib, config, pkgs, ... }:
let
  inherit (config.local.services) maintenance;
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
    filters = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ ];
    };
  };

  config = lib.mkIf (maintenance.mail.enable && config.local.services.postfix.enable) {
    systemd.services.auto-mail = {
      description = "NixOS maintenance mail service";
      serviceConfig.Type = "oneshot";
      startAt = maintenance.dates;

      script = let
        services = lib.strings.concatStringsSep " " (map (x: "\"" + x + "\"") config.systemd.services.auto-mail.after); 
        truncates = lib.strings.concatStringsSep " " (map (x: "\"" + x + "\"") maintenance.mail.filters);
        sendmail = "${pkgs.postfix}/bin/sendmail";
        inherit (config.local.services.postfix) sender;
        receivers = lib.strings.concatStringsSep "," maintenance.mail.recipients;
      in ''
        serviceList=(${services})
        truncateList=(${truncates})
        total=0
        success=0
        status="SUCCESS"

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
          for i in "''${truncateList[@]}"; do
            logs=$(echo "$logs" | grep -C2 --group-separator="-- truncated $(( $(echo "$logs" | grep -c "$i") - 4 )) lines --" -v "$i")
          done
          
          contents+=$'\n'"$(echo "$logs")"$'\n\n'
        done

        cat <<EOF | ${sendmail} -f ${sender} -t ${receivers}
        Subject: Maintenance Job [$success/$total]: $status
        Content-Type: text/plain; charset="UTF-8"

        $contents
        EOF
      '';

      after = [
        "auto-wol.service"
        "auto-pull.service"
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
