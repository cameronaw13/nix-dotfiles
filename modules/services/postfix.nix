{ lib, config, ... }:
let
  inherit (config.local) services;
  inherit (services.postfix) sender;
  inherit (config.networking) hostName;
  aliases = lib.strings.concatStringsSep ", " services.postfix.rootAliases;
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

  config = {
    services.postfix = {
    inherit (services.postfix) enable;
      relayHost = "smtp.gmail.com";
      relayPort = 587;
      config = {
        smtp_tls_security_level = "may";
        smtp_sasl_auth_enable = "yes";
        smtp_sasl_security_options = "";
        smtp_sasl_password_maps = "texthash:${config.sops.secrets."${hostName}/sasl-passwd".path}";
        # optional: Forward mails from root to user (e.g. cron, smartd)
        virtual_alias_maps = "inline:{ {root=${aliases}} }";
        smtp_header_checks = "pcre:/etc/postfix/header_checks";
      };
      enableHeaderChecks = lib.mkDefault true;
      headerChecks = [
        { 
          action = "REPLACE From: ${hostName} <${sender}>";
          pattern = "/^From:.*/";
        } 
      ];
    };

    sops.secrets."${hostName}/sasl-passwd" = {
      owner = config.services.postfix.user;
    };
  };
}
