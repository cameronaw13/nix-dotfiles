{ lib, config, ... }:
{
  options.homeusers.filesystem.enable = lib.mkEnableOption "filesystem home module";

  config = lib.mkIf config.homeusers.filesystem.enable {
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
