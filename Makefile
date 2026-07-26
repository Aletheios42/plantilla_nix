.PHONY: help prod dev debug ci ci-act lint test build format coverage clean update docker-build docker-run release-dry-run audit dev-up dev-down deploy-dev deploy-prod docs-serve docs-build

LINT_CMD ?=
TEST_CMD ?=
BUILD_CMD ?=
FORMAT_CMD ?=
COVERAGE_CMD ?=

define comprobar_cmd
	@if [ -z "$($(1))" ]; then \
		echo "Define $(1) en tu override o variable de entorno"; \
		exit 1; \
	fi
endef

help: ## Muestra esta ayuda
	@printf "\033[1;33mComandos disponibles:\033[0m\n"
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk -F'##' '{printf "\033[32m%-15s\033[0m %s\n", $$1, $$2}'

check:
	@command -v nix >/dev/null || { echo "Instala nix - https://nixos.org/download.html"; exit 1; }

prod: check ## Shell de produccion
	@exec nix develop .#prod

dev: ## Shell de desarrollo
	@exec nix develop .#dev

lint: check ## Ejecuta el linter (define LINT_CMD)
	$(call comprobar_cmd,LINT_CMD)
	@nix develop .#ci --command bash -c '$(LINT_CMD)'

test: check ## Ejecuta los tests (define TEST_CMD)
	$(call comprobar_cmd,TEST_CMD)
	@nix develop .#ci --command bash -c '$(TEST_CMD)'

build: check ## Compila el proyecto (define BUILD_CMD)
	$(call comprobar_cmd,BUILD_CMD)
	@nix develop .#ci --command bash -c '$(BUILD_CMD)'

format: check ## Formatea el codigo (define FORMAT_CMD)
	$(call comprobar_cmd,FORMAT_CMD)
	@nix develop .#ci --command bash -c '$(FORMAT_CMD)'

coverage: check ## Genera reporte de cobertura (define COVERAGE_CMD)
	$(call comprobar_cmd,COVERAGE_CMD)
	@nix develop .#ci --command bash -c '$(COVERAGE_CMD)'

clean: ## Limpia artifacts de build y cobertura
	@rm -rf dist/ build/ coverage/

update: check ## Actualiza el lock de Nix (nix flake update)
	@nix flake update

docker-build: check ## Build de imagen Docker para desarrollo local
	@test -f src/Dockerfile || { echo "No se encontro src/Dockerfile"; exit 1; }
	@docker build -t $(notdir $(CURDIR)):local src/

docker-run: check ## Ejecuta la imagen Docker local
	@docker run --rm -it $(notdir $(CURDIR)):local

release-dry-run: check ## Simula el release para ver la version que se generaria
	@nix develop .#ci --command bash -c 'semantic-release --dry-run --no-ci'

audit: check ## Auditoria de seguridad local del repo con Trivy
	@nix develop .#ci --command bash -c 'trivy fs --severity HIGH,CRITICAL .'

dev-up: check ## Crea el cluster k3d de desarrollo
	@nix develop .#ci --command bash -c 'k3d cluster create dev-cluster --config k3d-config.yaml'

dev-down: check ## Destruye el cluster k3d de desarrollo
	@nix develop .#ci --command bash -c 'k3d cluster delete dev-cluster'

deploy-dev: check ## Despliega en el cluster k3d local (kluctl -t dev)
	@nix develop .#ci --command bash -c 'kluctl deploy -t dev -y'

deploy-prod: check ## Despliega en produccion (kluctl -t prod)
	@nix develop .#ci --command bash -c 'kluctl deploy -t prod -y'

docs-serve: check ## Sirve la documentacion localmente (mkdocs serve)
	@nix develop .#dev --command bash -c 'mkdocs serve -a localhost:8000'

docs-build: check ## Genera el HTML de documentacion (mkdocs build)
	@nix develop .#ci --command bash -c 'mkdocs build'

ci: check format lint test build ## Pipeline CI completa

ci-act: check ## Simula la pipeline completa localmente con act
	@command -v act >/dev/null || { echo "Falta: act — https://github.com/nektos/act"; exit 1; }
	@command -v docker >/dev/null || command -v podman >/dev/null || { echo "Falta: docker o podman"; exit 1; }
	@act -j ci

all: help
