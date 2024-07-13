{ inputs, ... }:
{
  system.autoUpgrade = {
    enable = true;
    flake = inputs.self.outPath;
    flags = [
      # deprecated w/ no replacement lol
      "--update-input"
      "nixpkgs"
      "-L" # print build logs
    ];
    dates = "Mon *-*-* 02:00:00";
    persistent = true;
  };
}
