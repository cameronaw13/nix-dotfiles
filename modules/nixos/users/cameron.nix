{ lib, config, pkgs, ... }:
{
  options.nixusers.cameron.enable = lib.mkEnableOption "enable cameron user module";

  config = lib.mkIf config.nixusers.cameron.enable { 
    users.users.cameron = {
      isNormalUser = true;
      description = "cameron";
      initialPassword = "cameron";
      extraGroups = [ "networkmanager" "wheel" ];
      packages = with pkgs; [
        # Multi-host userwide packages
      ];
    };
  };
}
