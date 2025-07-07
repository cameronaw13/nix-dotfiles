{ lib, config, repoPath, scrtPath, stateVersion, inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
  
  options.local.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule ({ name, lib, ... }: {
      options = {
        username = lib.mkOption {
          type = lib.types.passwdEntry lib.types.str;
          default = name;
        };
        uid = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
        };
        extraGroups = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        linger = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        sopsNix = lib.mkOption {
          type = lib.types.bool;
          default = false;
        };
        authorizedKeys = lib.mkOption {
          type = lib.types.listOf lib.types.singleLineStr;
          default = [ ];
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
    default = { };
  };

  config = let
    inherit (config.networking) hostName;
    userList = lib.attrsets.mapAttrsToList (name: _: name) config.local.users;
  in lib.getAttrs [ "users" "home-manager" "sops" ] (
    lib.mapAttrs (_: list: lib.mkMerge list) (lib.foldAttrs (name: accu: [ name ] ++ accu) [ ] (
    map (username: let
      currUser = config.local.users.${username};
      sopsDir = "${hostName}/${username}";
    in {
      users.users.${username} = {
        inherit (currUser) uid extraGroups linger;
        isNormalUser = true;
        description = lib.mkDefault username;
        hashedPasswordFile = lib.mkIf (
          builtins.hasAttr "${sopsDir}/hashedPassword" config.sops.secrets
          ) config.sops.secrets."${sopsDir}/hashedPassword".path;
        openssh.authorizedKeys.keys = currUser.authorizedKeys ++ lib.optionals (
          builtins.hasAttr "${sopsDir}/authorizedKeys" config.sops.secrets
          ) (lib.splitString "\n" (builtins.readFile config.sops.secrets."${sopsDir}/authorizedKeys".path)
        );
      };

      home-manager.users.${username} = {
        home = {
          inherit username stateVersion;
          homeDirectory = "/home/${username}";
          packages = currUser.userPackages;
        };
        
        imports = [
          ./homepkgs/default.nix
        ];
        
        local.homepkgs = lib.mkMerge [
          { 
            inherit repoPath scrtPath hostName sopsDir;
            inherit (currUser) sopsNix;
            isWheel = builtins.elem "wheel" currUser.extraGroups;
          }
          currUser.homePackages
        ];
        
        sops = lib.mkIf currUser.sopsNix {
          age.keyFile = "/home/${username}/.config/sops/age/keys.txt";
          defaultSopsFile = "${inputs.nix-secrets}/secrets.yaml";
        };
      };
      
      sops.secrets = lib.mkIf currUser.sopsNix {
        "${sopsDir}/hashedPassword".neededForUsers = true;
      };
    }) userList))
  );
}
