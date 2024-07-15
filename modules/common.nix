{ pkgs, ... }:
{
  /* Global Nix Options */
  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];
  nix.settings.allowed-users = [ "@wheel" ];

  /* Global Environment Options */
  environment.systemPackages = with pkgs; [
    # Multi-host system packages
    inxi
    pciutils
    trash-cli
    tree
  ];
  environment.shellAliases = {
    rm = "echo \"Consider using 'trash' or use the full command: $(which rm)\"";
    mv = "mv -i";
    cp = "cp -i";
  };

  /* Global Locale Options */
  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";
}
