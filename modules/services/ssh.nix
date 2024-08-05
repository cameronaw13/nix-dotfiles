{ lib, config, ... }:
{
  options.local.services.ssh.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };

  config = lib.mkIf config.local.services.ssh.enable {
    services.openssh = {
      enable = lib.mkDefault true;
      settings = {
        PermitRootLogin = "no";
      };
    };
  };
}
