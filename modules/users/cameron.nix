{ lib, config, inputs, ... }:
let
  username = "cameron";
  hostname = config.usermgmt.cameron.hostname;
in
{
  options.usermgmt.${username} = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    hostname = lib.mkOption {
      type = lib.types.str;
    };
  };

  config = lib.mkIf config.usermgmt.${username}.enable {
    sops.secrets."${hostname}/${username}/password".neededForUsers = true;
    users.mutableUsers = false;
    
    users.users.${username} = {
      isNormalUser = true;
      description = username;
      hashedPasswordFile = config.sops.secrets."${hostname}/${username}/password".path;
      extraGroups = [ "networkmanager" "wheel" ];
      # TODO: add authorized keys through sops-nix
    };

    home-manager.sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
    ];

    home-manager.users.${username} = {
      home = {
        username = username;
        homeDirectory = "/home/${username}";
        stateVersion = "24.05";
      };

      imports = [
        ../programs/default.nix
      ];
      homepkgs.hostname = hostname;

      sops = {
        age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
        defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
      };

      programs.bash = {
        enable = true;
        bashrcExtra = ''
          alias sudo="sudo ";
        '';
      };
    };
  };
}
