{ lib, config, pkgs, ... }:
let
  inherit (config.local) homepkgs;
  inherit (config.home) username;
in
{
  options.local.homepkgs.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    username = lib.mkOption {
      type = lib.types.nullOr lib.types.singleLineStr;
      default = null;
    };
    email = lib.mkOption {
      type = lib.types.nullOr lib.types.singleLineStr;
      default = null;
    };
    signing = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    gh.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf homepkgs.git.enable {
    programs = {
      git = {
        enable = true;
        package = pkgs.gitMinimal;
        userName = homepkgs.git.username;
        userEmail = homepkgs.git.email;
        extraConfig = lib.mkMerge [
          { 
            init.defaultBranch = "master";
            safe.directory = [ "/etc/nixos" "/etc/nixos/secrets" ];
          }
          (lib.mkIf (homepkgs.git.signing && homepkgs.sopsNix) {
            commit.gpgsign = true;
            gpg.format = "ssh";
            gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
            user.signingkey = "~/.ssh/id_ed25519_key.pub";
          })
        ];
      };
      ssh = {
        enable = lib.mkDefault true;
        matchBlocks."github-key" = {
          host = "github.com";
          identitiesOnly = true;
          identityFile = [
            "~/.ssh/id_ed25519_key"
          ];
        };
      };
      gh = lib.mkIf homepkgs.git.gh.enable {
        enable = true;
        settings.git_protocol = "ssh";
      };
    };

    sops = lib.mkIf homepkgs.sopsNix {
      secrets = {
        "${homepkgs.sopsDir}/id_ed25519_key" = {
          path = "/home/${username}/.ssh/id_ed25519_key";
        };
        "${homepkgs.sopsDir}/id_ed25519_key.pub" = {
          path = "/home/${username}/.ssh/id_ed25519_key.pub";
        };
      };
      templates."allowed_signers" = {
        content = "* ${config.sops.placeholder."${homepkgs.sopsDir}/id_ed25519_key.pub"}";
        path = "/home/${username}/.ssh/allowed_signers";
      };
    };
  };
}
