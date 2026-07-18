# github_template

## Descripcion
Base template for new repositories.

## Structure
```
.
├── flake.nix                        # Nix devShell, con los paquetes adecuados por perfil
├── flake.lock                       # Pinned nixpkgs
├── makefile                         # make help
└── .github/
    ├── CODEOWNERS.md
    ├── PULL_REQUEST_TEMPLATE.md
    └── workflows/
        └── ci.yml                   # CI (commented, enable per project)
```

## Usage
```bash
git clone git@github.com:Aletheios42/github_template.git my-project
cd my-project
rm -rf .git
git init
git add .
git commit -m "chore: init from template"
```

## Requirements

- Nix with flakes enabled

## Customization

- `flake.nix` — replace `pkgs.example1 pkgs.example2` with project dependencies
- `ci.yml` — uncomment and configure the pipeline
- `CODEOWNERS.md` — update `@Aletheios42` with team members
