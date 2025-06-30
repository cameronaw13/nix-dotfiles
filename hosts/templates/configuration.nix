{ pkgs, inputs, ... }:
{
  imports = [
    #./hardware-configuration.nix
    ./extra-hardware-conf.nix
    ../../modules/default.nix
    inputs.sops-nix.nixosModules.sops
    # inputs.microvm.nixosModules.host
  ];

  /* Local Config */
  local = {
    users.bootstrap = {
      extraGroups = [ "wheel" ];
      sudoBypass = true;
      userPackages = builtins.attrValues {
        inherit (pkgs)
        gitMinimal
        gh
        ;
      };
      authorizedKeys = [
        # eg: "ssh-ed25519 AAAA... nixos@dotfiles"
      ];
    };
    services.openssh.enable = true;
  };

  /* Virtual Console */
  console = {
    earlySetup = true;
    #font = "ter-v28b";
    keyMap = "us";
  };
}
