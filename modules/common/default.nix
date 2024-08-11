{ lib, pkgs, inputs, ... }:
{
  imports = [
    ./upgrade-diff.nix
  ];

  /* Environment */
  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];
  environment = {
    systemPackages = with pkgs; [
      # Multi-host system packages
      trash-cli
      sops
    ];
    shellAliases = {
      rm = "echo \"Consider using 'trash' or use the full command: $(which rm)\"";
      mv = "mv -i";
      cp = "cp -i";
    };
  };

  /* Users */
  users.mutableUsers = false;
  home-manager.sharedModules = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  /* Locale */
  time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  /* Security */
  security.sudo.execWheelOnly = lib.mkDefault true;
  nix.settings.trusted-users = lib.mkDefault [ "root" "@wheel" ];

  /* Cleanup */
  nix.settings.auto-optimise-store = lib.mkDefault true;
  boot.tmp.cleanOnBoot = lib.mkDefault true;

  /* Performance */
  nix.settings.connect-timeout = lib.mkDefault 10; # cache.nixos.org timeout
  nix.daemonCPUSchedPolicy = lib.mkDefault "batch"; # nix daemon process priority
  nix.daemonIOSchedClass = lib.mkDefault "idle";
  nix.daemonIOSchedPriority = lib.mkDefault 7;
  systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkDefault 250; # kill nix builds before user services
}
