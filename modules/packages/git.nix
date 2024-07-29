{ lib, config, ... }:
let
  username = config.home.username;
  hostname = config.homepkgs.git.hostname;
in
{
  options.homepkgs.git.enable = lib.mkEnableOption "git config module";
  options.homepkgs.git.hostname = lib.mkOption {
    type = lib.types.str;
  };

  config = lib.mkIf config.homepkgs.git.enable {
    programs.git = {
      enable = lib.mkDefault true;
      userName = "cameronaw13";
      userEmail = "cameronawichman@gmail.com";
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
