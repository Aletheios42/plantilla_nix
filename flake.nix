{
  description = "Esto es un template para normalizar mis repositorios, recuerda cambiarla para tu proyecto específico";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in {
      devShells = forAllSystems (system: let
        pkgs = nixpkgs.legacyPackages.${system};
        commonPackages = [ ];
      in {
        prod = pkgs.mkShell {
          packages = commonPackages ++ [ ];
          env.profile = "PROD";
        };

        dev = pkgs.mkShell {
          packages = commonPackages ++ [ ];
          env.profile = "DEV";
        };

        ci = pkgs.mkShell {
          packages = commonPackages ++ [ ];
          env.profile = "CI";
        };
      });
    };
}
