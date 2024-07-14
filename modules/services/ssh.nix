{ lib, config, ... }:
{
  options.servicemgmt.ssh.enable = lib.mkEnableOption "ssh service module";

  config = lib.mkIf config.servicemgmt.ssh.enable {
    services.openssh = {
      enable = lib.mkDefault true;
      settings = {
        X11Forwarding = true;
        PermitRootLogin = "no";
      };
    };
  };
}
