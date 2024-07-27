{ lib, config, ... }:
let
  username = "cameron";
in
{
  options.usermgmt.${username}.enable = lib.mkEnableOption "${username} user module";

  config = lib.mkIf config.usermgmt.${username}.enable {
    sops.secrets = {
      "super_secret_password" = {
        owner = config.users.users.${username}.name;
        inherit (config.users.users.${username}) group;
      };
    };

    users.users.${username} = {
      isNormalUser = true;
      description = username;
      initialPassword = username;
      extraGroups = [ "networkmanager" "wheel" ];
    };
    
    home-manager.users.${username} = {
      home = {
        username = username;
        homeDirectory = "/home/${username}";
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
