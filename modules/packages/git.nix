{ lib, config, ... }:
{
  options.homepkgs.git.enable = lib.mkEnableOption "git config module";

  config = lib.mkIf config.homepkgs.git.enable {
    programs.git = {
      enable = lib.mkDefault true;
      userName = "cameronaw13";
      userEmail = "cameronawichman@gmail.com";
      extraConfig = {
        init.defaultBranch = "master";
        commit.gpgsign = true;
        gpg.format = "ssh";
        # Must be manually created
        gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
        user.signingkey = "~/.ssh/id_ed25519.pub";
      };
    };
  };
}
