# [NOMBRE DEL PROYECTO]

[![CI](https://github.com/TU_USUARIO/TU_REPO/actions/workflows/ci.yaml/badge.svg)](https://github.com/TU_USUARIO/TU_REPO/actions/workflows/ci.yaml)
[![Coverage](https://codecov.io/gh/TU_USUARIO/TU_REPO/branch/master/graph/badge.svg)](https://codecov.io/gh/TU_USUARIO/TU_REPO)
[![Release](https://github.com/TU_USUARIO/TU_REPO/actions/workflows/semantic-release.yaml/badge.svg)](https://github.com/TU_USUARIO/TU_REPO/actions/workflows/semantic-release.yaml)
[![License](https://img.shields.io/github/license/TU_USUARIO/TU_REPO)](./LICENSE)

> Descripcion corta del proyecto. Que hace, para quien es, y por que existe.

## Herramientas

| Herramienta | Proposito |
|---|---|
| [Nix](https://nixos.org) + flakes | Entornos de desarrollo reproducibles (`dev`, `prod`, `ci`) |
| [semantic-release](https://semantic-release.gitbook.io) | Versionado automatico basado en Conventional Commits |
| [Docker](https://docker.com) + ghcr.io | Build y push de imagenes OCI |
| [kluctl](https://kluctl.io) | Deploy GitOps push-based al cluster Kubernetes |
| [SOPS](https://github.com/getsops/sops) + [Age](https://github.com/FiloSottile/age) | Secretos encriptados en el repo, desencriptados en deploy |
| [k3d](https://k3d.io) | Cluster Kubernetes local para desarrollo |
| [CodeQL](https://codeql.github.com) | Analisis de seguridad estatico (SAST) |
| [Trivy](https://trivy.dev) | Escaneo de vulnerabilidades en imagenes Docker |
| [Codecov](https://codecov.io) | Reporte de cobertura de tests |
| [Renovate](https://docs.renovatebot.com) | Actualizacion automatica de dependencias |
| [MkDocs + Material](https://squidfunk.github.io/mkdocs-material/) | Documentacion estatica a partir de markdown |
| [actions/labeler](https://github.com/actions/labeler) | Etiquetado automatico de PRs segun archivos modificados |

## Estructura

```
.
├── .dockerignore                     # Exclusiones para el contexto de build Docker
├── .editorconfig                     # Formato consistente entre editores
├── .github/
│   ├── CODEOWNERS.md                 # Revisores automaticos por ruta
│   ├── copilot-instructions.md       # Instrucciones para Copilot Code Review
│   ├── labeler.yml                   # Reglas de auto-etiquetado de PRs
│   ├── PULL_REQUEST_TEMPLATE.md
│   ├── ISSUE_TEMPLATE/
│   └── workflows/
│       ├── ci.yaml                   # CI: lint + test + build en push y PR
│       ├── coverage.yaml              # Cobertura: genera reporte, sube a Codecov
│       ├── semantic-release.yaml     # Release automatico en push a master
│       ├── docker-build-push.yaml    # Build, push y escaneo Trivy de imagen en tags v*
│       ├── deploy.yaml               # Deploy con kluctl (workflow_call)
│       ├── labeler.yaml              # Auto-labeler de PRs
│       ├── codeql.yaml               # Analisis de seguridad SAST
│       └── docs.yaml                 # Build y deploy de documentacion (push a docs/)
├── .gitignore
├── .kluctl.yaml                      # Configuracion del proyecto kluctl (targets)
├── k3d-config.yaml                    # Configuracion del cluster k3d de desarrollo
├── mkdocs.yml                         # Configuracion de MkDocs + Material
├── docs/                              # Documentacion en markdown
│   ├── index.md
│   └── getting-started.md
├── .releaserc.yaml                   # Configuracion de semantic-release
├── .sops.yaml                         # Configuracion de SOPS (claves Age)
├── renovate.json                     # Configuracion de Renovate
├── CHANGELOG.md                      # Generado automaticamente por semantic-release
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── LICENSE
├── Makefile                          # make ci, make dev, make docs-serve, etc.
├── secrets/                          # Secretos encriptados con SOPS + Age
├── SECURITY.md
├── flake.lock
└── flake.nix                         # DevShells: dev, prod, ci
```

## CI/CD

El flujo completo de la pipeline:

```
push/PR a master
    │
    ├── ► ┌─────────────────┐
    │     │   ci.yaml       │  format + lint + test + build
    │     └─────────────────┘
    │
    ├── ► ┌─────────────────┐
    │     │  coverage.yaml  │  coverage report → Codecov + artifact
    │     └─────────────────┘
    │
    ▼ (solo en push a master)
┌──────────────────────┐
│  semantic-release    │  determina version, genera changelog,
│                      │  crea release + tag en GitHub
└──────────────────────┘
    │
    ▼ (se dispara con el nuevo tag v*)
┌──────────────────────┐
│  docker-build-push   │  build + push a ghcr.io
│  ├─ Trivy scan       │  escanea vulnerabilidades
│  └─ deploy           │  llama a kluctl deploy
└──────────────────────┘
    │
    ▼
┌──────────────────────┐
│  deploy.yaml         │  kluctl deploy al cluster
└──────────────────────┘
```

- `ci.yaml` se ejecuta en todo push y PR a `master`.
- `coverage.yaml` se ejecuta en push y PR a `master`. Genera el reporte, lo sube a Codecov y lo guarda como artifact.
- `semantic-release.yaml` solo en push a `master`. Analiza los commits desde el ultimo release y decide si crea uno nuevo.
- `docker-build-push.yaml` se dispara con tags `v*`. Construye la imagen, la escanea con Trivy (SARIF a GitHub Security), la sube a `ghcr.io` y llama a `deploy.yaml`.
- `deploy.yaml` ejecuta `kluctl deploy --fixed-image=<imagen>:<tag> -y` directamente al cluster.
- `docs.yaml` construye y despliega la documentacion a GitHub Pages en cada push a `docs/` o `mkdocs.yml`. Tambien se puede disparar manualmente (`workflow_dispatch`).

## Documentacion (MkDocs + Material)

La documentacion se escribe en markdown dentro de `docs/` y se construye con [MkDocs + Material for MkDocs](https://squidfunk.github.io/mkdocs-material/).

```bash
make docs-serve     # Servir localmente en localhost:8000 con hot reload
make docs-build     # Generar HTML estatico en site/
```

El workflow `docs.yaml` se ejecuta automaticamente en cada push que modifique `docs/**`, `mkdocs.yml` o el propio workflow. Construye el sitio y lo despliega en GitHub Pages.

Para activar GitHub Pages:
1. Ve a **Settings > Pages** en el repositorio.
2. En **Source**, selecciona **GitHub Actions**.
3. Asegurate de que el entorno `github-pages` exista en **Settings > Environments**.

## Coverage

El reporte de cobertura se genera con `make coverage` (define `COVERAGE_CMD` apuntando a tu herramienta: `pytest --cov`, `npm run coverage`, etc.). El workflow `coverage.yaml` ejecuta el comando, sube el reporte a [Codecov](https://codecov.io) y lo guarda como artifact de GitHub Actions.

Para repositorios privados, configura el secret `CODECOV_TOKEN`. En repos publicos el token es opcional.

## Gestion de secretos (SOPS + Age)

Los secretos del proyecto se gestionan con [SOPS](https://github.com/getsops/sops) y [Age](https://github.com/FiloSottile/age). Se almacenan encriptados en `secrets/` y se commitean al repositorio sin riesgo — solo quienes tengan la clave privada Age correspondiente pueden desencriptarlos.

### Configuracion inicial

```bash
make secrets-init
```

Esto genera tu par de claves Age en `~/.config/sops/age/keys.txt` y te muestra la clave publica. Copiala y añadela a `.sops.yaml`:

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    age: >-
      age1...TU_CLAVE_PUBLICA     # <-- tu clave publica
      age1...CLAVE_CI              # <-- clave del CI (opcional)
```

Para que otros colaboradores puedan desencriptar, añade sus claves publicas a `.sops.yaml` y ejecuta `make secrets-rekey`.

### Crear secretos de desarrollo

```bash
make secrets-edit
```

Esto abre `secrets/dev.yaml` con SOPS. Las claves de primer nivel se exportan como variables de entorno durante el deploy:

```yaml
database_url: postgres://...
jwt_secret: supersecure
```

### Despliegue con secretos

Los targets `deploy-dev` y `deploy-prod` detectan automaticamente si existe un archivo de secretos:

```bash
make deploy-dev     # Si secrets/dev.yaml existe → sops exec --decrypt → kluctl deploy
make deploy-prod    # Si secrets/prod.yaml existe → sops exec --decrypt → kluctl deploy
```

En los manifiestos de kluctl, referencias las variables con `${database_url}`, `${jwt_secret}`, etc.

### CI/CD

Para que GitHub Actions pueda desencriptar, genera un keypair dedicado para CI:

1. `age-keygen -o ci-age-key.txt`
2. Guarda la clave privada como secret `SOPS_AGE_KEY` en el repositorio
3. Añade la clave publica a `.sops.yaml` y ejecuta `make secrets-rekey`

SOPS detecta automaticamente `SOPS_AGE_KEY` del entorno en el pipeline.

## Seguridad

El pipeline incluye dos capas de escaneo:

- **CodeQL** — analisis estatico (SAST) del codigo fuente. Corre semanalmente y en PRs a master. Configuracion `security-extended`.
- **Trivy** — escaneo de vulnerabilidades en la imagen Docker construida. Corre post-push (no bloquea el deploy). Los resultados se suben como SARIF a la pestana Security de GitHub.

Para auditoria local: `make audit` (Trivy en modo filesystem).

## Copilot Code Review

El repositorio incluye `.github/copilot-instructions.md` con las reglas de revision en español. Para activar la revision automatica de PRs:

1. Ve a **Settings > Rules > Rulesets** en el repositorio.
2. Haz clic en **New branch ruleset**.
3. En **Target branches**, selecciona `master` (o usa `Default branch`).
4. Activa la opcion **"Automatically request Copilot code review"**.
5. Opcional: configura el resto de protecciones (requerir PR, aprobaciones, etc.).
6. Haz clic en **Create**.

A partir de ese momento, cada PR abierta recibira una revision automatica de Copilot siguiendo las instrucciones de `.github/copilot-instructions.md`.

## Requisitos

- [Nix](https://nixos.org/download.html) con flakes habilitados
- Docker o Podman (solo para `make ci-act`)

## Uso

```bash
git clone git@github.com:TU_USUARIO/TU_REPO.git mi-proyecto
cd mi-proyecto
rm -rf .git && git init
git add . && git commit -m "chore: init from template"
```

### Personalizacion

1. Reemplaza `TU_USUARIO` y `TU_REPO` en los badges y URLs de este README.
2. `flake.nix` — ajusta las dependencias en los shells `dev`, `prod`, `ci`.
3. `Makefile` — define `LINT_CMD`, `TEST_CMD`, `BUILD_CMD`, `FORMAT_CMD` y `COVERAGE_CMD` para tu proyecto.
4. `mkdocs.yml` — cambia `[NOMBRE DEL PROYECTO]` y la URL del repo.
5. `.kluctl.yaml` — configura los `targets` con los contextos de tu cluster.
6. `k3d-config.yaml` — ajusta el nombre y configuracion del cluster de desarrollo.
7. `.github/CODEOWNERS.md` — actualiza `@Aletheios42` con los revisores reales.
8. `.releaserc.yaml` — ajusta `branches` si usas ramas adicionales (`next`, `beta`, `alpha`).
9. `.sops.yaml` — reemplaza `age1...TU_CLAVE_PUBLICA` con tu clave publica Age (generada con `make secrets-init`).
10. `secrets/` — crea `secrets/dev.yaml` con `make secrets-edit`; anade los secretos que necesite tu app.
11. `CODE_OF_CONDUCT.md` — actualiza `[TU_EMAIL]@ejemplo.com`.
12. `SECURITY.md` — actualiza `[TU_EMAIL]@ejemplo.com`.
13. `renovate.json` — instala la [GitHub App](https://github.com/apps/renovate) en el repo.
14. Codecov — asegura que `CODECOV_TOKEN` este configurado en los secrets del repositorio (necesario para repos privados).

### Comandos disponibles

```bash
make help           # Muestra todos los comandos
make dev            # Shell de desarrollo (nix develop .#dev)
make prod           # Shell de produccion (nix develop .#prod)
make ci             # Pipeline CI completa (format + lint + test + build)
make ci-act         # Simula GitHub Actions localmente con act
make coverage       # Genera reporte de cobertura (COVERAGE_CMD)
make format         # Formatea el codigo (FORMAT_CMD)
make clean          # Limpia artifacts de build y cobertura
make update         # Actualiza flake.lock
make docker-build   # Build de imagen Docker local
make docker-run     # Ejecuta imagen Docker local
make release-dry-run # Simula el release para ver la version
make audit          # Auditoria de seguridad con Trivy (modo filesystem)
make dev-up         # Crea cluster k3d local
make dev-down       # Destruye cluster k3d local
make deploy-dev     # Despliega en cluster k3d (con secretos si existen)
make deploy-prod    # Despliega en produccion (con secretos si existen)
make secrets-init   # Genera par de claves Age para SOPS
make secrets-edit   # Edita secretos de desarrollo (sops)
make secrets-rekey  # Re-encripta todos los secretos
make docs-serve     # Sirve documentacion localmente (localhost:8000)
make docs-build     # Genera HTML de documentacion
```

Define las variables antes de ejecutar `make ci`:

```bash
export FORMAT_CMD="npm run format"
export LINT_CMD="npm run lint"
export TEST_CMD="npm test"
export BUILD_CMD="npm run build"
make ci
```

Y para cobertura:

```bash
export COVERAGE_CMD="npm run coverage"
make coverage
```

## Convenciones de commit

Este proyecto sigue [Conventional Commits](https://www.conventionalcommits.org/):

| Tipo | Descripcion |
|---|---|
| `feat` | Nueva funcionalidad |
| `fix` | Correccion de bug |
| `refactor` | Refactorizacion sin cambios funcionales |
| `docs` | Solo documentacion |
| `test` | Anadir o actualizar pruebas |
| `chore` | Mantenimiento, CI, dependencias |

Los mensajes con `BREAKING CHANGE` en el cuerpo producen un release `major`.

## Contribuir

Lee [CONTRIBUTING.md](./CONTRIBUTING.md) para conocer el flujo de trabajo, como abrir PRs y las convenciones del proyecto.

## Codigo de conducta

Lee [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md) para conocer las normas de nuestra comunidad.

## Seguridad

Lee [SECURITY.md](./SECURITY.md) para reportar vulnerabilidades.
