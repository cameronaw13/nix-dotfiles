{ lib, config, ... }:
let
  username = "filesystem";
in
{
  options.usermgmt.${username}.enable = lib.mkOption {
    type = lib.types.bool;
    default = false;
  };

  config = lib.mkIf config.usermgmt.${username}.enable {
    users.users.${username} = {
      isNormalUser = true;
      description = username;
      initialPassword = username;
    };
    
    home-manager.users.${username} = {
      home = {
        username = username;
        homeDirectory = "/home/${username}";
        stateVersion = "24.05";
      };

      imports = [
        ../programs/default.nix
      ];

      programs.bash = {
        enable = true;
        bashrcExtra = ''
        '';
      };
    };
  };
}
