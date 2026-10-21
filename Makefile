# mlterm-fb — local build
#
# The recipe lives in arch-repo (PKGBUILDs/mlterm-fb), which tracks mlterm
# releases and publishes to the [aaronsb] pacman repo and the AUR. This repo
# keeps the docs and a container build of that recipe for local testing.
#
#   make build     fetch the recipe, build it in a throwaway Arch container -> out/
#   make install   pacman -U the freshly built package
#   make clean     remove out/ and the fetched recipe
#
# To test an arch-repo edit before its PR, point RECIPE at the local file:
#   make build RECIPE=../../../system/arch/arch-repo/PKGBUILDs/mlterm-fb/PKGBUILD

RECIPE_URL ?= https://raw.githubusercontent.com/aaronsb/arch-repo/main/PKGBUILDs/mlterm-fb/PKGBUILD
RECIPE     ?=

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@awk 'BEGIN{FS=":.*##"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: recipe
recipe: ## Fetch arch-repo's PKGBUILD into recipe/ (RECIPE=path to use a local file)
	@mkdir -p recipe
	@if [ -n "$(RECIPE)" ]; then \
		echo ">> recipe from $(RECIPE)"; \
		cp "$(RECIPE)" recipe/PKGBUILD; \
	else \
		echo ">> recipe from $(RECIPE_URL)"; \
		curl -fsSL "$(RECIPE_URL)" -o recipe/PKGBUILD; \
	fi

.PHONY: build
build: recipe ## Build the package in a container -> out/
	./build.sh

.PHONY: install
install: ## Install the most recently built package (sudo pacman -U)
	@pkg=$$(ls -t out/mlterm-fb-[0-9]*.pkg.tar.zst 2>/dev/null | head -1); \
	if [ -z "$$pkg" ]; then echo "No package in out/ — run 'make build' first." >&2; exit 1; fi; \
	echo ">> sudo pacman -U $$pkg"; \
	sudo pacman -U "$$pkg"

.PHONY: clean
clean: ## Remove build outputs and the fetched recipe
	rm -rf out recipe .aur
