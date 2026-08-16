# Google Drive Backup Utility — distribution package
#
# Typical flow:
#   make setup          download the package for this machine, extract it, create your .env
#   nano app/.env       fill in your configuration
#   make run            foreground test run
#   make install        register as a systemd service (Linux)
#   make start / stop   control the service
#
# Packages are published per-platform on separate branches of this repo (not on
# master): linux -> gdrive-backup-utility.tar.gz (x86_64) or
# gdrive-backup-utility-linux-arm64.tar.gz, macos -> gdrive-backup-utility-macos.tar.gz.
# `make setup`/`make update` detect this machine's OS/arch and download the
# matching package straight from its branch. Windows has no make-based flow —
# download gdrive-backup-utility-windows.zip from the windows branch by hand
# (see README).

SHELL := /bin/bash
APP_DIR ?= app
DIST_REPO := https://github.com/m-tech-org/google-drive-backup-utility

UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Darwin)
  BRANCH := macos
  TARBALL := gdrive-backup-utility-macos.tar.gz
else ifneq (,$(filter $(UNAME_M),aarch64 arm64))
  BRANCH := linux
  TARBALL := gdrive-backup-utility-linux-arm64.tar.gz
else
  BRANCH := linux
  TARBALL := gdrive-backup-utility.tar.gz
endif

PKG_URL := $(DIST_REPO)/raw/$(BRANCH)/$(TARBALL)

.DEFAULT_GOAL := help

.PHONY: help fetch extract setup run ui install start stop status logs uninstall clean update

SERVICE := gdrive-backup-utility.service

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Detected platform: $(UNAME_S)/$(UNAME_M) -> $(TARBALL) (branch: $(BRANCH))"
	@echo "On Windows, download gdrive-backup-utility-windows.zip by hand — see README."

fetch: ## Download the package for this machine's OS/arch
	curl -fsSL -o $(TARBALL) "$(PKG_URL)"
	@echo "Downloaded $(TARBALL) from the $(BRANCH) branch"

extract: fetch ## Download + unpack the app into ./$(APP_DIR)
	mkdir -p $(APP_DIR)
	tar -xzf $(TARBALL) -C $(APP_DIR)
	chmod +x $(APP_DIR)/*.sh $(APP_DIR)/gdrive-backup-utility
	@echo "Extracted to ./$(APP_DIR)"

setup: extract ## Download + extract + create .env from the template (then edit it!)
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

update: ## Re-download the latest package for this platform and upgrade in place (keeps .env and cred/)
	@echo "Checking $(BRANCH) branch for a newer $(TARBALL)..."
	@curl -fsSL -o $(TARBALL).new "$(PKG_URL)"
	@if [ -f $(TARBALL) ] && cmp -s $(TARBALL) $(TARBALL).new; then \
		echo "Already on the latest published version."; \
		rm -f $(TARBALL).new; \
	else \
		mv -f $(TARBALL).new $(TARBALL); \
		if [ ! -d $(APP_DIR) ]; then \
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
		fi; \
	fi

clean: ## Remove the extracted app directory and downloaded package (DELETES app/.env and app/cred!)
	@echo "This deletes ./$(APP_DIR) including its .env and cred/. Press Ctrl+C to abort."
	@sleep 3
	rm -rf $(APP_DIR) $(TARBALL)
