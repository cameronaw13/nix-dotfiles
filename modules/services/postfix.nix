{ lib, config, ... }:
{
  options.servicemgmt.postfix.enable = lib.mkEnableOption "postfix service module";

  config = lib.mkIf config.servicemgmt.postfix.enable {
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
        virtual_alias_maps = "inline:{ {root=cameronawichman@gmail.com} }";
        smtp_header_checks = pcre:/etc/postfix/header_checks;
      };
      enableHeaderChecks = true;
      headerChecks = [
        { 
          action = "REPLACE From: ${config.networking.hostName} <cameronserverlog@gmail.com>";
          pattern = "/^From:.*/";
        }
      ];
    };

    sops.secrets."postfix/sasl-passwd" = {
      owner = config.services.postfix.user;
    };
  };
}
