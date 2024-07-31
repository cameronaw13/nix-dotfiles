{ lib, config, ... }:
{
  options.servicemgmt.ssh.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf config.servicemgmt.ssh.enable {
    services.openssh = {
      enable = lib.mkDefault true;
      settings = {
        PermitRootLogin = "no";
      };
    };
  };
}
