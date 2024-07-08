{ lib, config, ... }:
{
  options.ssh-service.enable = lib.mkEnableOption "enable ssh service module";

  config = lib.mkIf config.ssh-service.enable {
    services.openssh = {
      enable = lib.mkDefault true;
      settings = {
        X11Forwarding = true;
        PermitRootLogin = "no";
      };
    };
  };
}
