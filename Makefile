.PHONY: help prod dev debug ci ci-act lint test build

LINT_CMD ?=
TEST_CMD ?=
BUILD_CMD ?=

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

ci: check lint test build ## Pipeline CI completa

ci-act: check ## Simula la pipeline completa localmente con act
	@command -v act >/dev/null || { echo "Falta: act — https://github.com/nektos/act"; exit 1; }
	@command -v docker >/dev/null || command -v podman >/dev/null || { echo "Falta: docker o podman"; exit 1; }
	@act -j ci

all: help
