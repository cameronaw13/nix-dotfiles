{ lib, pkgs, inputs, ... }:
{
  imports = [
    ./activate.nix
  ];

  /* Environment */
  environment = {
    systemPackages = with pkgs; [
      # Multi-host system packages
      trash-cli
    ];
    shellAliases = {
      rm = "echo Consider using 'trash' or use the full command: \''\$(type -P rm)'\'";
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

  /* Nix Settings */
  nix = {
    settings = {
      extra-experimental-features = [ "nix-command" "flakes" ];
      trusted-users = lib.mkDefault [ "root" "@wheel" ];
      auto-optimise-store = lib.mkDefault true;
      connect-timeout = lib.mkDefault 10; # cache.nixos.org timeout
    };
    daemonCPUSchedPolicy = lib.mkDefault "batch"; # nix daemon process priority
    daemonIOSchedClass = lib.mkDefault "idle";
    daemonIOSchedPriority = lib.mkDefault 7;
  };

  /* Other */
  security.sudo.execWheelOnly = lib.mkDefault true;
  systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkDefault 250; # kill nix builds before user services
  boot.kernel.sysctl."kernel.sysrq" = 1;
}
