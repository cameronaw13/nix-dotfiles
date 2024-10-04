{ modulesPath, inputs, ... }:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.disko.nixosModules.disko
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  disko.devices.disk = {
    TEMP_DISKS
  };

  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    TEMP_KEY
  ];
  
  system.stateVersion = "24.05";
}
