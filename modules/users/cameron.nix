{ lib, config, inputs, ... }:
let
  username = "cameron";
  hostname = config.networking.hostName;
in
{
  options.local.users.${username} = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf config.local.users.${username}.enable {
    sops.secrets."${hostname}/${username}/password".neededForUsers = true;
    
    users.users.${username} = {
      isNormalUser = true;
      description = username;
      hashedPasswordFile = config.sops.secrets."${hostname}/${username}/password".path;
      extraGroups = [ "networkmanager" "wheel" ];
      # TODO: add authorized keys through sops-nix
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
      local.homepkgs.hostname = hostname;

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
