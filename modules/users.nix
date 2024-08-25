{ lib, config, inputs, ... }:
{
  options.local.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({ name, lib, ... }: {
      options = {
        username = lib.mkOption {
          type = lib.types.passwdEntry lib.types.str;
          default = name;
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
    }));
  };

  config = let
    inherit (config.local) users;
    hostname = config.networking.hostName;
    userList = lib.attrsets.mapAttrsToList (name: value: name) users;
  in {
    sops.secrets = lib.mkMerge (map (username: {
      "${hostname}/${username}/password".neededForUsers = true;
    }) userList);
    
    users.users = lib.mkMerge (map (username: {
      ${username} = {
        isNormalUser = true;
        description = username;
        hashedPasswordFile = config.sops.secrets."${hostname}/${username}/password".path;
        uid = users.${username}.uid;
        extraGroups = users.${username}.groups;
        linger = users.${username}.linger;
      };
    }) userList);

    home-manager.users = lib.mkMerge (map (username: {
      ${username} = {
        home = {
          inherit (username);
          homeDirectory = "/home/${username}";
          stateVersion = "24.05";
          packages = users.${username}.packages;
        };
        
        imports = [
          ./homepkgs/default.nix
        ];
        local.homepkgs.hostname = hostname;
        
        sops = {
          age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
          defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
        };
      };
    }) userList);
  };
}
