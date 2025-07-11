{ lib, pkgs, repoPath, stateVersion, inputs, ... }:
{
  imports = [
    ./activate.nix
    ./users.nix
    ./services
  ];

  /* Environment */
  environment = {
    # Multi-host system packages
    systemPackages = builtins.attrValues {
      inherit (pkgs)
      nh
      trash-cli
      ;
    };
    variables = {
      NH_FLAKE = repoPath;
    };
    shellAliases = {
      rm = "echo Consider using 'trash' or use the full command: \''\$(type -P rm)'\'";
      mv = "mv -i";
      cp = "cp -i";
    };
  };

  /* Locale */
  time.timeZone = lib.mkDefault "America/Los_Angeles";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  /* Nix Settings */
  nix = {
    settings = {
      extra-experimental-features = [ "nix-command" "flakes" ];
      trusted-users = [ "@wheel" ];
      auto-optimise-store = lib.mkDefault true;
      connect-timeout = lib.mkDefault 10; # cache.nixos.org timeout
    };
    daemonCPUSchedPolicy = lib.mkDefault "batch"; # nix daemon process priority
    daemonIOSchedClass = lib.mkDefault "idle";
    daemonIOSchedPriority = lib.mkDefault 7;
  };

  /* Nix Security */
  security.sudo = {
    execWheelOnly = lib.mkDefault true;
    extraConfig = lib.mkDefault ''
      Defaults lecture = never
    '';
  };

  /* Systemd */
  boot.initrd.systemd.suppressedUnits = [
    "emergency.service"
    "emergency.target"
  ];
  systemd = {
    enableEmergencyMode = lib.mkDefault false;
    sleep.extraConfig = lib.mkDefault ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };

  /* Users */
  users.mutableUsers = lib.mkDefault false;
  home-manager.sharedModules = [
    inputs.sops-nix.homeManagerModules.sops
    inputs.nixCats.homeModule
  ];

  /* Known Hosts */
  programs.ssh.knownHosts = {
    "github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
    "gitlab.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAfuCHKVTjquxvt6CM6tdG4SLp1Btn/nOeHHE5UOzRdf";
  };

  /* "Debloat" */
  fonts.fontconfig.enable = lib.mkDefault false;
  xdg = {
    autostart.enable = lib.mkDefault false;
    icons.enable = lib.mkDefault false;
    menus.enable = lib.mkDefault false;
    mime.enable = lib.mkDefault false;
    sounds.enable = lib.mkDefault false;
  };
  
  /* Other */
  boot.kernel.sysctl."kernel.sysrq" = lib.mkDefault 1;
  systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkDefault 250; # kill nix builds before user services

  /* Statever */
  system = { inherit stateVersion; };
}
