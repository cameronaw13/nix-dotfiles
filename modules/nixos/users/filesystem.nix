{ lib, config, pkgs, ... }:
{
  options.nixusers.filesystem.enable = lib.mkEnableOption "enable filesystem user module";

  config = lib.mkIf config.nixusers.filesystem.enable {
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
