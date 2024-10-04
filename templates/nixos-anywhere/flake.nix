{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    dikso = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
  };

  outputs = { nixpkgs, ... } @inputs: {
    nixosConfigurations = {
      template-server = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          ./configuration.nix
        ];
      };
    };
  };
}
