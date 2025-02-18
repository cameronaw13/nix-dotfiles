{ lib, config, ... }:
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
  };

  config = lib.mkIf homepkgs.git.enable {
    programs.git = {
      enable = lib.mkDefault true;
      userName = homepkgs.git.username;
      userEmail = homepkgs.git.email;
      extraConfig = lib.mkMerge [
        { 
          init.defaultBranch = "master";
          safe.directory = [ "/etc/nixos" "/etc/nixos/secrets" ];
        }
        (lib.mkIf homepkgs.git.signing {
          commit.gpgsign = true;
          gpg.format = "ssh";
          gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
          user.signingkey = "~/.ssh/id_ed25519.pub";
        })
      ];
    };

    sops = lib.mkIf homepkgs.sopsNix {
      secrets = {
        "${homepkgs.sopsDir}/id_ed25519" = {
          path = "/home/${username}/.ssh/id_ed25519";
        };
        "${homepkgs.sopsDir}/id_ed25519.pub" = {
          path = "/home/${username}/.ssh/id_ed25519.pub";
        };
        /*"${homepkgs.sopsDir}/allowed_signers" = {
          path = "/home/${username}/.ssh/allowed_signers";
        };*/
      };
      templates."allowed_signers" = {
        content = "* ${config.sops.placeholder."${homepkgs.sopsDir}/id_ed25519.pub"}";
        path = "/home/${username}/.ssh/allowed_signers";
      };
    };
  };
}
