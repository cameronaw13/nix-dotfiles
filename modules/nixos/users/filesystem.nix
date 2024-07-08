{ lib, config, pkgs, ... }:
{
  options.filesystem-user.enable = lib.mkEnableOption "enable filesystem user module";

  config = lib.mkIf config.filesystem-user.enable {
    users.users.filesystem = {
      isNormalUser = true;
      description = "filesystem";
      initialPassword = "filesystem";
      packages = with pkgs; [
        # Multi-host userwide packages
      ];
    };
  };
}
