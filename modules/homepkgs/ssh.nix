{ lib, config, ... }:
let
  inherit (config.local) homepkgs;
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
        "config" = {
          host = "github.com";
          identitiesOnly = true;
          identityFile = [
            "~/.ssh/id_ed25519"
          ];
        };
      };
    };

    home.file.known_hosts = lib.mkIf homepkgs.git.enable {
      target = ".ssh/known_hosts";
      force = true;
      text = ''
        github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
      '';
    };
  };
}
