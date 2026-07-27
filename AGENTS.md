# AGENTS.md — Instrucciones para agentes de IA

## Principios generales

- Responde siempre en español.
- Antes de ejecutar cualquier comando de lint, test, build, format o coverage, verifica que las variables `LINT_CMD`, `TEST_CMD`, `BUILD_CMD`, `FORMAT_CMD` y `COVERAGE_CMD` esten definidas. Si no lo estan, preguntale al usuario que comandos usar.
- Todos los comandos de CI deben ejecutarse dentro de un shell Nix (`nix develop .#ci` o `make <target>`). No asumas que herramientas como `semantic-release`, `trivy` o `kluctl` estan disponibles globalmente.
- Los commits deben seguir Conventional Commits: `feat`, `fix`, `refactor`, `docs`, `test`, `chore` con formato `tipo(scope): descripcion`.

## Shells de desarrollo (flake.nix)

El proyecto define 3 shells de desarrollo en `flake.nix`. Cada uno establece la variable de entorno `profile` al valor correspondiente.

| Shell | Comando | Perfil | Paquetes incluidos | Cuando usarlo |
|---|---|---|---|---|
| `dev` | `nix develop .#dev` o `make dev` | `DEV` | mkdocs-material, sops, age | Desarrollo diario, editar docs, gestionar secretos |
| `prod` | `nix develop .#prod` o `make prod` | `PROD` | mkdocs-material, sops, age | Entorno de produccion (mismos paquetes que dev, distinto perfil) |
| `ci` | `nix develop .#ci` | `CI` | todo lo anterior + act, semantic-release, kluctl, k3d, trivy | CI/CD, despliegue, auditoria, simulacion de pipelines |

**Regla**: Usa `make dev` para trabajo diario; usa `make ci` o `nix develop .#ci --command bash -c '...'` para comandos de CI.

## Makefile — comandos disponibles

### Variables requeridas

Antes de ejecutar `lint`, `test`, `build`, `format` o `coverage`, el usuario debe definir las variables correspondientes. Si no estan definidas el Makefile fallara con un mensaje de error.

```bash
export LINT_CMD="npm run lint"        # o ruff check, eslint, etc.
export TEST_CMD="npm test"            # o pytest, cargo test, etc.
export BUILD_CMD="npm run build"      # o cargo build, make, etc.
export FORMAT_CMD="npm run format"    # o ruff format, prettier, etc.
export COVERAGE_CMD="npm run coverage" # o pytest --cov, etc.
```

### Desarrollo diario

| Comando | Que hace | Shell usado |
|---|---|---|
| `make dev` | Abre shell de desarrollo con perfil `DEV` | `.#dev` |
| `make prod` | Abre shell de produccion con perfil `PROD` | `.#prod` |
| `make docs-serve` | Sirve documentacion en `localhost:8000` con hot reload | `.#dev` |
| `make docs-build` | Genera HTML estatico en `site/` | `.#ci` |
| `make clean` | Elimina `dist/`, `build/`, `coverage/` | ninguno (nativo) |
| `make update` | Actualiza `flake.lock` (`nix flake update`) | ninguno (nativo) |

### CI y calidad de codigo

| Comando | Que hace | Shell usado |
|---|---|---|
| `make format` | Formatea el codigo usando `FORMAT_CMD` | `.#ci` |
| `make lint` | Ejecuta el linter usando `LINT_CMD` | `.#ci` |
| `make test` | Ejecuta los tests usando `TEST_CMD` | `.#ci` |
| `make build` | Compila el proyecto usando `BUILD_CMD` | `.#ci` |
| `make coverage` | Genera reporte de cobertura usando `COVERAGE_CMD` | `.#ci` |
| `make ci` | Pipeline completa: `format` → `lint` → `test` → `build` | `.#ci` |
| `make ci-act` | Simula GitHub Actions localmente con `act` | nativo + act |

**Regla**: Despues de hacer cambios en el codigo, ejecuta `make ci` para verificar que todo funciona. Si el usuario pide lint, test o build, usa los targets individuales del Makefile, no los comandos directamente.

### Docker

| Comando | Que hace | Requisito |
|---|---|---|
| `make docker-build` | Build de imagen Docker desde `src/Dockerfile` | Debe existir `src/Dockerfile` |
| `make docker-run` | Ejecuta la imagen Docker local | Haber ejecutado `make docker-build` primero |

### Kubernetes y despliegue

| Comando | Que hace | Shell usado |
|---|---|---|
| `make dev-up` | Crea cluster k3d local (`dev-cluster`) | `.#ci` |
| `make dev-down` | Destruye cluster k3d local | `.#ci` |
| `make deploy-dev` | Despliega en k3d con `kluctl -t dev` (con secretos si `secrets/dev.yaml` existe) | `.#ci` |
| `make deploy-prod` | Despliega en produccion con `kluctl -t prod` (con secretos si `secrets/prod.yaml` existe) | `.#ci` |

### Secretos (SOPS + Age)

| Comando | Que hace | Shell usado |
|---|---|---|
| `make secrets-init` | Genera par de claves Age en `~/.config/sops/age/keys.txt` | `.#ci` |
| `make secrets-edit` | Abre `secrets/dev.yaml` con SOPS para editar | `.#ci` |
| `make secrets-rekey` | Re-encripta todos los secretos con las claves actuales de `.sops.yaml` | `.#ci` |

### Seguridad y releases

| Comando | Que hace | Shell usado |
|---|---|---|
| `make audit` | Auditoria de seguridad con Trivy (solo HIGH y CRITICAL) | `.#ci` |
| `make release-dry-run` | Simula `semantic-release` para ver que version se generaria | `.#ci` |

## Flujo de trabajo tipico

### Al empezar a trabajar

```bash
make dev          # Entrar al shell de desarrollo
```

### Al hacer cambios

```bash
export FORMAT_CMD="npm run format"
export LINT_CMD="npm run lint"
export TEST_CMD="npm test"
export BUILD_CMD="npm run build"
make ci           # Ejecutar pipeline completa
```

### Antes de commitear

```bash
make ci           # Verificar que todo pasa
```

### Al trabajar con secretos

```bash
make secrets-init   # Solo la primera vez, para generar claves Age
make secrets-edit   # Editar secrets/dev.yaml
make secrets-rekey  # Despues de añadir/quitar claves en .sops.yaml
```

### Al desplegar

```bash
make dev-up        # Crear cluster k3d local
make deploy-dev    # Desplegar en desarrollo
make dev-down      # Destruir cluster al terminar
```

## Notas para agentes de IA

1. **Siempre usa los targets del Makefile** para lint, test, build, format y coverage. No ejecutes los comandos subyacentes directamente, porque el Makefile se encarga de comprobar que Nix esta instalado y de ejecutar todo dentro del shell `.#ci` correcto.

2. **Pregunta por las variables si no estan definidas.** Si el usuario no ha exportado `LINT_CMD`, `TEST_CMD`, etc., los targets fallaran. Pregunta cual es el comando correcto para su proyecto antes de ejecutar.

3. **El orden de `make ci` es fijo**: format → lint → test → build. Si el usuario pide solo una de estas fases, usa el target individual (`make lint`, `make test`, etc.).

4. **Documentacion**: para previsualizar la documentacion usa `make docs-serve` (shell `.#dev`). Para construir el HTML final usa `make docs-build` (shell `.#ci`).

5. **No asumas disponibilidad de herramientas.** `semantic-release`, `trivy`, `kluctl`, `k3d`, `act`, `sops` y `age` solo estan disponibles dentro del shell `.#ci`. Si necesitas usarlas, hazlo a traves del Makefile o con `nix develop .#ci --command bash -c '...'`.

6. **Estructura esperada**: el proyecto espera un `src/Dockerfile` para `make docker-build`. Los secretos viven en `secrets/` (encriptados con SOPS). La configuracion de despliegue esta en `.kluctl.yaml` y `k3d-config.yaml`.
