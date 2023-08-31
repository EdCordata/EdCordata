.DEFAULT_GOAL := convert_cv


# Variables
# =============================================================================
VAR_DOCKER_EXE   := docker compose
VAR_COMPOSE_FILE := docker-compose.yml

DOCKER := $(VAR_DOCKER_EXE) -f $(VAR_COMPOSE_FILE)
# =============================================================================


# Core Commands
# =============================================================================

build:
	$(DOCKER) build --no-cache

convert_cv:
	$(DOCKER) run --rm md-to-pdf
	$(MAKE) fix_permissions

fix_permissions:
	sudo chown -R $(USER):$(USER) ./doki

# =============================================================================
