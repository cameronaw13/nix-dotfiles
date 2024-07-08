{ lib, config, pkgs, ... }:
{
  options.cameron-user.enable = lib.mkEnableOption "enable cameron user module";

  config = lib.mkIf config.cameron-user.enable { 
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
