{ lib, config, ... }:
let
  inherit (config.local) homepkgs;
  inherit (config.home) username;
in
{
  options.local.homepkgs.ssh = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
    };
  };

  config = lib.mkIf homepkgs.ssh.enable {
    programs.ssh = {
      enable = lib.mkDefault true;
      matchBlocks = {
        "github-key" = lib.mkIf homepkgs.git.enable {
          host = "github.com";
          identitiesOnly = true;
          identityFile = [
            "~/.ssh/id_ed25519_key"
          ];
        };
      };
    };

    /*sops.templates."known_hosts" = lib.mkIf (homepkgs.sopsNix && homepkgs.git.enable) {
      content = "github.com ${config.sops.placeholder."${homepkgs.sopsDir}/id_ed25519.key.pub"}";
      path = "/home/${username}/.ssh/known_hosts";
    };*/

    home.file.known_hosts = lib.mkIf (homepkgs.git.enable && homepkgs.sopsNix) {
      target = ".ssh/known_hosts";
      force = true;
      text = ''
        github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
      '';
    };
  };
}
