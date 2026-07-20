# Google Drive Backup Utility — distribution package
#
# Typical flow:
#   make setup          extract the app and create your .env
#   nano app/.env       fill in your configuration
#   make run            foreground test run
#   make install        register as a systemd service (Linux)
#   make start / stop   control the service

SHELL := /bin/bash
TARBALL := gdrive-backup-utility.tar.gz
APP_DIR ?= app

.DEFAULT_GOAL := help

.PHONY: help extract setup run ui install start stop status logs uninstall clean update

SERVICE := gdrive-backup-utility.service

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

extract: ## Unpack the app into ./$(APP_DIR)
	mkdir -p $(APP_DIR)
	tar -xzf $(TARBALL) -C $(APP_DIR)
	chmod +x $(APP_DIR)/*.sh $(APP_DIR)/gdrive-backup-utility
	@echo "Extracted to ./$(APP_DIR)"

setup: extract ## Extract + create .env from the template (then edit it!)
	@if [ ! -f $(APP_DIR)/.env ]; then \
		cp $(APP_DIR)/.env.example $(APP_DIR)/.env; \
		echo "Created $(APP_DIR)/.env — edit it before running:  nano $(APP_DIR)/.env"; \
	else \
		echo "$(APP_DIR)/.env already exists"; \
	fi

run: ## Run in the foreground (first run performs Google authentication)
	cd $(APP_DIR) && ./run.sh

ui: ## Launch the graphical control panel
	cd $(APP_DIR) && ./gdrive-backup-utility --ui

install: ## Register as a systemd service that starts at boot (Linux)
	cd $(APP_DIR) && ./install.sh

start: ## Start the systemd service
	cd $(APP_DIR) && ./start.sh

stop: ## Stop the systemd service
	cd $(APP_DIR) && ./stop.sh

status: ## Show service status
	systemctl status gdrive-backup-utility.service --no-pager

logs: ## Follow the application logs
	tail -f $(APP_DIR)/log/*.log

uninstall: ## Remove the systemd service
	cd $(APP_DIR) && ./uninstall.sh

update: ## Fetch the latest published version and upgrade (keeps your .env and cred/)
	@git fetch origin
	@LOCAL=$$(git rev-parse HEAD); UPSTREAM=$$(git rev-parse @{u} 2>/dev/null || echo "$$LOCAL"); \
	if [ "$$LOCAL" = "$$UPSTREAM" ]; then \
		echo "Already on the latest published version."; \
	else \
		echo "New version available — updating..."; \
		git pull --ff-only; \
	fi
	@if [ ! -d $(APP_DIR) ]; then \
		echo "No existing installation — running setup instead."; \
		$(MAKE) --no-print-directory setup; \
	else \
		WAS_RUNNING=0; \
		if systemctl is-active --quiet $(SERVICE) 2>/dev/null; then \
			WAS_RUNNING=1; echo "Stopping service for the upgrade..."; sudo systemctl stop $(SERVICE); \
		fi; \
		tar -xzf $(TARBALL) -C $(APP_DIR); \
		chmod +x $(APP_DIR)/*.sh $(APP_DIR)/gdrive-backup-utility; \
		echo "Upgraded ./$(APP_DIR) — your .env and cred/ were preserved."; \
		if [ $$WAS_RUNNING -eq 1 ]; then \
			echo "Restarting service..."; sudo systemctl start $(SERVICE); \
		else \
			echo "Service was not running; start it with 'make start' when ready."; \
		fi; \
	fi

clean: ## Remove the extracted app directory (keeps the tarball; DELETES app/.env and app/cred!)
	@echo "This deletes ./$(APP_DIR) including its .env and cred/. Press Ctrl+C to abort."
	@sleep 3
	rm -rf $(APP_DIR)
