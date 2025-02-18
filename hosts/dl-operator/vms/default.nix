{ lib, ... }:
{
  options.local.microvms = {
    link = lib.mkOption {
      type = lib.types.str;
      default = "ens18";
    };
    caddy = {
      mac = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:01";
      };
    };
    blocky = {
      mac = lib.mkOption {
        type = lib.types.str;
        default = "02:00:00:00:00:02";
      };
    };
  };
}
