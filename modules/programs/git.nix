{ lib, config, ... }:
let
  username = config.home.username;
  hostname = config.local.homepkgs.hostname;
in
{
  options.local.homepkgs.git = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
    username = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
    email = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };
  };

  config = lib.mkIf config.local.homepkgs.git.enable {
    programs.git = {
      enable = lib.mkDefault true;
      userName = config.local.homepkgs.git.username;
      userEmail = config.local.homepkgs.git.email;
      extraConfig = {
        init.defaultBranch = "master";
        commit.gpgsign = true;
        gpg.format = "ssh";
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        user.signingkey = "~/.ssh/id_ed25519.pub";
      };
    };

    sops.secrets = {
      "${hostname}/${username}/id_ed25519" = {
        path = "/home/${username}/.ssh/id_ed25519";
      };
      "${hostname}/${username}/id_ed25519.pub" = {
        path = "/home/${username}/.ssh/id_ed25519.pub";
      };
      "${hostname}/${username}/allowed_signers" = {
        path = "/home/${username}/.ssh/allowed_signers";
      };
    };
  };
}
