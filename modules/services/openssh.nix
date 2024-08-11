{ lib, config, ... }:
{
  options.local.services.openssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf config.local.services.openssh.enable {
    services.openssh = {
      enable = lib.mkDefault true;
      settings = {
        PermitRootLogin = "no";
      };
    };
  };
}
