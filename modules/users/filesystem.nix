{ lib, config, inputs, pkgs, ... }:
let
  username = "filesystem";
  hostname = config.networking.hostName;
  inherit (config.local) users;
in
{
  options.local.users.${username} = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    uid = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
    };
    groups = lib.mkOption {
      type = lib.types.listOf lib.types.singleLineStr;
      default = [ ];
    };
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
    };
    linger = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf users.${username}.enable {
    sops.secrets."${hostname}/${username}/password".neededForUsers = true;
    
    users.users.${username} = {
      isNormalUser = true;
      description = username;
      hashedPasswordFile = config.sops.secrets."${hostname}/${username}/password".path;
      uid = users.${username}.uid;
      extraGroups = users.${username}.groups;
      linger = users.${username}.linger;
      # TODO: add authorized keys through sops-nix
    };

    home-manager.users.${username} = {
      home = {
        inherit (username);
        homeDirectory = "/home/${username}";
        stateVersion = "24.05";
        packages = users.${username}.packages;
      };

      imports = [
        ./programs/default.nix
      ];
      local.homepkgs.hostname = hostname;

      sops = {
        age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
        defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
      };
    };
  };
}
