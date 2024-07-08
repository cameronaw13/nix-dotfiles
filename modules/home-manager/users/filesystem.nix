{ lib, config, ... }:
{
  options.filesystem-home.enable = lib.mkEnableOption "enable filesystem home module";

  config = lib.mkIf config.filesystem-home.enable {
    home-manager.users.filesystem = {
      home = {
        username = "filesystem";
        homeDirectory = "/home/filesystem";
        stateVersion = "24.05";
      };

      imports = [
        ../packages/default.nix
      ];

      programs.bash = {
        enable = true;
        #bashrcExtra = '' '';
      };
    };
  };
}
