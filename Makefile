# mlterm-fb — build & publish
#
# This repo is the single source of truth for the framebuffer-only mlterm
# package. PKGBUILD is canonical; everything below derives from it.
#
#   make build     build the package in a throwaway Arch container -> out/
#   make install   pacman -U the freshly built package
#   make srcinfo   regenerate .SRCINFO from PKGBUILD (host makepkg)
#   make verify    fail if .SRCINFO is stale relative to PKGBUILD
#   make publish   sync PKGBUILD + .SRCINFO to the AUR and push
#   make clean     remove out/ and the .aur/ working clone
#
# `make publish` manages its own gitignored clone of the AUR repo (.aur/),
# so the AUR's separate git history stays out of this repo. It is the only
# target that touches the network/AUR; everything else is local.

AUR_REMOTE ?= ssh://aur@aur.archlinux.org/mlterm-fb.git
AUR_DIR    := .aur

# Pull version straight from the PKGBUILD so commit messages stay honest.
PKGVER := $(shell awk -F= '/^pkgver=/{print $$2}' PKGBUILD)
PKGREL := $(shell awk -F= '/^pkgrel=/{print $$2}' PKGBUILD)
VERSION := $(PKGVER)-$(PKGREL)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@awk 'BEGIN{FS=":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: build
build: ## Build the package in a container -> out/
	./build.sh

.PHONY: install
install: ## Install the most recently built package (sudo pacman -U)
	@pkg=$$(ls -t out/mlterm-fb-[0-9]*.pkg.tar.zst 2>/dev/null | head -1); \
	if [ -z "$$pkg" ]; then echo "No package in out/ — run 'make build' first." >&2; exit 1; fi; \
	echo ">> sudo pacman -U $$pkg"; \
	sudo pacman -U "$$pkg"

.PHONY: srcinfo
srcinfo: ## Regenerate .SRCINFO from PKGBUILD
	makepkg --printsrcinfo > .SRCINFO
	@echo ">> .SRCINFO regenerated for $(VERSION)"

.PHONY: verify
verify: ## Fail if .SRCINFO is out of date with PKGBUILD
	@makepkg --printsrcinfo > .SRCINFO.tmp; \
	if ! diff -q .SRCINFO .SRCINFO.tmp >/dev/null 2>&1; then \
		rm -f .SRCINFO.tmp; \
		echo "ERROR: .SRCINFO is stale — run 'make srcinfo' and commit." >&2; \
		exit 1; \
	fi; \
	rm -f .SRCINFO.tmp; \
	echo ">> .SRCINFO is current ($(VERSION))"

.PHONY: publish
publish: verify ## Sync PKGBUILD + .SRCINFO to the AUR and push
	@if [ -d "$(AUR_DIR)/.git" ]; then \
		echo ">> refreshing $(AUR_DIR)"; \
		git -C "$(AUR_DIR)" fetch --quiet origin && git -C "$(AUR_DIR)" reset --hard --quiet origin/master; \
	else \
		echo ">> cloning $(AUR_REMOTE) -> $(AUR_DIR)"; \
		git clone --quiet "$(AUR_REMOTE)" "$(AUR_DIR)"; \
	fi
	@cp PKGBUILD .SRCINFO "$(AUR_DIR)/"
	@if git -C "$(AUR_DIR)" diff --quiet; then \
		echo ">> AUR already up to date with $(VERSION); nothing to push."; \
	else \
		git -C "$(AUR_DIR)" add PKGBUILD .SRCINFO; \
		git -C "$(AUR_DIR)" commit --quiet -m "mlterm-fb $(VERSION)"; \
		git -C "$(AUR_DIR)" push origin master; \
		echo ">> published mlterm-fb $(VERSION) to AUR"; \
	fi

.PHONY: clean
clean: ## Remove build outputs and the AUR working clone
	rm -rf out "$(AUR_DIR)"
