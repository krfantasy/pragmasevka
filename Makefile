.PHONY: help, check-prereqs
help: ## Show this help
	@egrep -h '\s##\s' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

check-prereqs: ## Check if all required tools are installed
	@command -v node >/dev/null 2>&1 || { echo "❌ Node.js required but not installed. Install with: brew install node"; exit 1; }
	@command -v npm >/dev/null 2>&1 || { echo "❌ npm required but not installed. Install with: brew install node"; exit 1; }
	@command -v fontforge >/dev/null 2>&1 || { echo "❌ FontForge required but not installed. Install with: brew install fontforge"; exit 1; }
	@command -v ttfautohint >/dev/null 2>&1 || { echo "❌ ttfautohint required but not installed. Install with: brew install ttfautohint"; exit 1; }
	@command -v zip >/dev/null 2>&1 || { echo "❌ zip required but not installed. Install with: brew install zip"; exit 1; }
	@echo "✅ All prerequisites installed"

font: ## Run all build steps in correct order
	@$(MAKE) check-prereqs
	@$(MAKE) ttf
	@$(MAKE) package

ttf: ## Build ttf font from `Pragmasevka` custom configuration
	@echo "🔨 Building Iosevka TTF fonts..."
	# Download latest Iosevka release if not exists
	@[ -d "$(CURDIR)/build/iosevka" ] || \
		(echo "📥 Fetching latest Iosevka release..." && \
		IOSEVKA_VERSION=$$(curl -sL "https://github.com/be5invis/Iosevka/releases" | \
			grep -o 'releases/tag/v[^"]*' | head -1 | sed 's/.*v//'); \
		echo "📦 Downloading Iosevka $$IOSEVKA_VERSION..." && \
		mkdir -p $(CURDIR)/build && \
		cd $(CURDIR)/build && \
		curl -sL "https://github.com/be5invis/Iosevka/archive/refs/tags/v$$IOSEVKA_VERSION.tar.gz" | \
			tar xz && \
		mv "Iosevka-$$IOSEVKA_VERSION" iosevka)
	# Copy build plan
	@echo "📋 Copying private-build-plans.toml..."
	@cp $(CURDIR)/private-build-plans.toml "$(CURDIR)/build/iosevka/private-build-plans.toml"
	# Install dependencies and build
	@echo "📦 Installing Iosevka dependencies..."
	@cd "$(CURDIR)/build/iosevka" && npm install
	@echo "🔧 Building TTF fonts..."
	@cd "$(CURDIR)/build/iosevka" && npm run build -- ttf::pragmasevka ttf::pragmasevka-mono --jCmd=4
	# Run FontForge punctuation script
	@echo "✒️  Patching punctuation glyphs..."
	@fontforge -script "$(CURDIR)/punctuation.py" "$(CURDIR)/build/iosevka/dist/pragmasevka/TTF/pragmasevka"
	@fontforge -script "$(CURDIR)/punctuation.py" "$(CURDIR)/build/iosevka/dist/pragmasevka-mono/TTF/pragmasevka-mono"
	# Create output directory
	@mkdir -p $(CURDIR)/dist/ttf
	# Copy TTF files
	@echo "📂 Copying TTF files to dist/ttf..."
	@cp "$(CURDIR)/build/iosevka/dist/pragmasevka/TTF"/*.ttf $(CURDIR)/dist/ttf/
	# Remove semibold and black variants
	@echo "🧹 Cleaning up unwanted variants..."
	@rm -rf $(CURDIR)/dist/ttf/*semibold*.ttf
	@rm -rf $(CURDIR)/dist/ttf/*black*.ttf
	@rm -rf $(CURDIR)/dist/ttf/punctuation.py
	# Rename files to match expected naming
	@echo "🏷️  Renaming files..."
	@mv "$(CURDIR)/dist/ttf/pragmasevka-normalbolditalic.ttf" "$(CURDIR)/dist/ttf/pragmasevka-bolditalic.ttf"
	@mv "$(CURDIR)/dist/ttf/pragmasevka-normalboldupright.ttf" "$(CURDIR)/dist/ttf/pragmasevka-bold.ttf"
	@mv "$(CURDIR)/dist/ttf/pragmasevka-normalregularitalic.ttf" "$(CURDIR)/dist/ttf/pragmasevka-italic.ttf"
	@mv "$(CURDIR)/dist/ttf/pragmasevka-normalregularupright.ttf" "$(CURDIR)/dist/ttf/pragmasevka-regular.ttf"
	# Copy and process mono TTF files
	@echo "📂 Copying pragmasevka-mono TTF files to dist/ttf..."
	@cp "$(CURDIR)/build/iosevka/dist/pragmasevka-mono/TTF"/*.ttf $(CURDIR)/dist/ttf/
	@echo "🧹 Cleaning up unwanted mono variants..."
	@rm -rf $(CURDIR)/dist/ttf/*-mono*semibold*.ttf
	@rm -rf $(CURDIR)/dist/ttf/*-mono*black*.ttf
	@echo "🏷️  Renaming mono files..."
	@mv "$(CURDIR)/dist/ttf/pragmasevka-mono-normalbolditalic.ttf" "$(CURDIR)/dist/ttf/pragmasevka-mono-bolditalic.ttf"
	@mv "$(CURDIR)/dist/ttf/pragmasevka-mono-normalboldupright.ttf" "$(CURDIR)/dist/ttf/pragmasevka-mono-bold.ttf"
	@mv "$(CURDIR)/dist/ttf/pragmasevka-mono-normalregularitalic.ttf" "$(CURDIR)/dist/ttf/pragmasevka-mono-italic.ttf"
	@mv "$(CURDIR)/dist/ttf/pragmasevka-mono-normalregularupright.ttf" "$(CURDIR)/dist/ttf/pragmasevka-mono-regular.ttf"
	@echo "✅ TTF build complete"

package: ## Pack fonts to ready-to-distribute archive
	zip -jr $(CURDIR)/dist/Pragmasevka.zip $(CURDIR)/dist/ttf/*.ttf

clean:
	rm -rf $(CURDIR)/dist/*
	rm -rf $(CURDIR)/build/*
