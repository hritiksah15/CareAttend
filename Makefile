# CareAttend — developer convenience targets.
# Usage: make <target>
.DEFAULT_GOAL := help
.PHONY: help install lint test precommit run build-web docker app-test

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?## "}{printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

install: ## Install backend dependencies + dev tools
	cd backend && pip install -r requirements.txt && pip install ruff pre-commit detect-secrets
	pre-commit install

lint: ## Lint the backend with ruff
	cd backend && ruff check .

test: ## Run the backend test suite
	cd backend && DATABASE_URL="sqlite:////tmp/careattend_dev.sqlite" FLASK_DEBUG=0 pytest -q

precommit: ## Run all pre-commit hooks on all files
	pre-commit run --all-files

run: ## Start the backend (DB + API) locally
	cd backend && ./run.sh

build-web: ## Build the Flutter web release
	cd care_attend_app && flutter build web --release

app-test: ## Analyze + test the Flutter app
	cd care_attend_app && flutter analyze --no-fatal-infos && flutter test

docker: ## Build the production backend image
	docker build -t careattend-backend ./backend
