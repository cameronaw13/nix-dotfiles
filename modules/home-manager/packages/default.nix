{ lib, ... }:
{
  imports = [
    ./vim.nix
    ./git.nix
    ./htop.nix
  ];
  # Togglable user-specific packages
  vim-cfg.enable = lib.mkDefault false;
  git-cfg.enable = lib.mkDefault false;
  htop-cfg.enable = lib.mkDefault false;
}
