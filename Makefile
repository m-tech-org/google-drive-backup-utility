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

.PHONY: help extract setup run ui install start stop status logs uninstall clean

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

clean: ## Remove the extracted app directory (keeps the tarball; DELETES app/.env and app/cred!)
	@echo "This deletes ./$(APP_DIR) including its .env and cred/. Press Ctrl+C to abort."
	@sleep 3
	rm -rf $(APP_DIR)
