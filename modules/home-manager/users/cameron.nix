{ lib, config, ... }:
{
  options.homeusers.cameron = {
    enable = lib.mkEnableOption "cameron home module";
  };

  config = lib.mkIf config.homeusers.cameron.enable {
    home-manager.users.cameron = {
      home = {
        username = "cameron";
        homeDirectory = "/home/cameron";
        stateVersion = "24.05";
      };
      
      imports = [
        ../packages/default.nix
      ];

      programs.bash = {
        enable = true;
        bashrcExtra = ''
          alias sudo="sudo ";
        '';
      };
    };
  };
}
