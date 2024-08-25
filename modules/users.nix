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
        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        linger = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        userPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          default = [ ];
        };
        homePackages = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
        };
      };
    }));
  };

  config = let
    inherit (config.local) users;
    hostname = config.networking.hostName;
    userList = lib.attrsets.mapAttrsToList (name: _: name) users;
  in {
    sops.secrets = lib.mkMerge (map (username: {
      "${hostname}/${username}/password".neededForUsers = true;
    }) userList);
    
    users.users = lib.mkMerge (map (username: {
      ${username} = {
        isNormalUser = true;
        description = username;
        hashedPasswordFile = config.sops.secrets."${hostname}/${username}/password".path;
        inherit (users.${username}) uid extraGroups linger;
      };
    }) userList);

    home-manager.users = lib.mkMerge (map (username: {
      ${username} = {
        home = {
          inherit (username);
          homeDirectory = "/home/${username}";
          stateVersion = "24.05";
          packages = users.${username}.userPackages;
        };
        
        imports = [
          ./homepkgs/default.nix
        ];
        local.homepkgs = lib.mkMerge [
          users.${username}.homePackages
          { inherit hostname; }
        ];
        
        sops = {
          age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
          defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
        };
      };
    }) userList);
  };
}
