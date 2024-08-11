{ lib, config, ... }:
let
  hostname = config.networking.hostName;
  sender = config.local.services.postfix.sender;
  aliases = lib.strings.concatStringsSep ", " config.local.services.postfix.rootAliases;
in
{
  options.local.services.postfix = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    sender = lib.mkOption {
      type = lib.types.str;
      default = "";
    };
    rootAliases = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ "" ];
    };
  };

  config = lib.mkIf config.local.services.postfix.enable {
    services.postfix = {
      enable = lib.mkDefault true;
      relayHost = "smtp.gmail.com";
      relayPort = 587;
      config = {
        smtp_use_tls = "yes";
        smtp_sasl_auth_enable = "yes";
        smtp_sasl_security_options = "";
        smtp_sasl_password_maps = "texthash:${config.sops.secrets."postfix/sasl-passwd".path}";
        # optional: Forward mails to root (e.g. from cron jobs, smartd) to me privately:
        virtual_alias_maps = "inline:{ {root=${aliases}} }";
        smtp_header_checks = pcre:/etc/postfix/header_checks;
      };
      enableHeaderChecks = true;
      headerChecks = [
        { 
          action = "REPLACE From: ${hostname} <${sender}>";
          pattern = "/^From:.*/";
        }
      ];
    };

    sops.secrets."postfix/sasl-passwd" = {
      owner = config.services.postfix.user;
    };
  };
}
