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

  config = lib.mkIf (homepkgs.ssh.enable && homepkgs.git.enable) {
    home.file.known_hosts = {
      enable = lib.mkDefault true;
      target = ".ssh/known_hosts";
      force = true;
      text = ''
        github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl
      '';
    };

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
  };
}
