{ lib, config, ... }:
let
  homepkgs = config.local.homepkgs;
  username = config.home.username;
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
        { init.defaultBranch = "master"; }
        (lib.mkIf homepkgs.git.signing {
          commit.gpgsign = true;
          gpg.format = "ssh";
          gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
          user.signingkey = "~/.ssh/id_ed25519.pub";
        })
      ];
    };

    sops.secrets = {
      "${homepkgs.hostname}/${username}/id_ed25519" = {
        path = "/home/${username}/.ssh/id_ed25519";
      };
      "${homepkgs.hostname}/${username}/id_ed25519.pub" = {
        path = "/home/${username}/.ssh/id_ed25519.pub";
      };
      "${homepkgs.hostname}/${username}/allowed_signers" = {
        path = "/home/${username}/.ssh/allowed_signers";
      };
    };
  };
}
