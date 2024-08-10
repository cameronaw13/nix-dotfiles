{ lib, pkgs, inputs, ... }:
{
  # NOTE: May need to separate common settings between bare-metal and microvm hosts

  /* Global Nix Options */
  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];
  nix.settings.connect-timeout = lib.mkDefault 5;

  /* Global Environment Options */
  environment.systemPackages = with pkgs; [
    # Multi-host system packages
    trash-cli
    sops
  ];
  environment.shellAliases = {
    rm = "echo \"Consider using 'trash' or use the full command: $(which rm)\"";
    mv = "mv -i";
    cp = "cp -i";
  };

  /* Global Locale Options */
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  /* Global User Management */  
  users.mutableUsers = false;
  home-manager.sharedModules = [
    inputs.sops-nix.homeManagerModules.sops
  ];

  /* Security */
  security.sudo.execWheelOnly = lib.mkDefault true;
  nix.settings.trusted-users = lib.mkDefault [ "root" "@wheel" ];

  /* Optimisations */
  nix.settings.auto-optimise-store = lib.mkDefault true;
  nix.settings.min-free = lib.mkDefault (7000 * 1024 * 1024); # 7000 MiB, Start when free space < min-free
  nix.settings.max-free = lib.mkDefault (7000 * 1024 * 1024); # 7000 MiB, Stop when used space < max-free
  systemd.services.nix-daemon.serviceConfig.OOMScoreAdjust = lib.mkDefault 250; # Move nix build OOM priority before user services
  boot.tmp.cleanOnBoot = lib.mkDefault true;

  /* Systemd */
  systemd = {
    watchdog = lib.mkDefault {
      runtimeTime = "1min"; # time system hangs before reboot
      rebootTime = "3min"; # time reboot hangs before force reboot
    };
    sleep.extraConfig = lib.mkDefault ''
      AllowSuspend=no
      AllowHibernation=no
    '';
  };
}
