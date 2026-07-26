{
  description = "Esto es un template para normalizar mis repositorios, recuerda cambiarla para tu proyecto específico";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems f;
    in {
      devShells = forAllSystems (system: let
        pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
        mkdocs-with-material = pkgs.python3.withPackages (ps: [ ps.mkdocs-material ps.mkdocs ]);
        commonPackages = [ mkdocs-with-material pkgs.sops pkgs.age ];
      in {
        prod = pkgs.mkShell {
          packages = commonPackages;
          env.profile = "PROD";
        };
        dev = pkgs.mkShell {
          packages = commonPackages;
          env.profile = "DEV";
        };
        ci = pkgs.mkShell {
          packages = commonPackages ++ [
            pkgs.act
            pkgs.semantic-release
            pkgs.kluctl
            pkgs.k3d
            pkgs.trivy
          ];
          env.profile = "CI";
        };
      });
    };
}
