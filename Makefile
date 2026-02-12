UNAME_S := $(shell uname -s)
SWIFT_FLAGS ?= --disable-sandbox
SWIFT_PACKAGE_VERSION := $(shell swift package tools-version)

# Repository name on GitHub Pages
REPO_NAME ?= ecs
# Subdirectory for versioned documentation (e.g., main, 1.0.0)
DOCS_VERSION_PATH ?= main

# The full base path for hosting
HOSTING_BASE_PATH ?= $(REPO_NAME)/$(DOCS_VERSION_PATH)

.PHONY: setup generate-code lint lint-fix test test-coverage testReadme build-debug build-release docs docs-preview docs-generate docs-coverage docs-check-coverage docs-check-links preview-analysis-docs generate-docs-githubpages pre-commit clean clean-sourcery

# --- Setup ---

setup:
	@which -s brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	@brew update
	@echo "Detected Package Swift Version: $(SWIFT_PACKAGE_VERSION)"
	@which mint > /dev/null || (echo "Mint not found. Installing via Homebrew..." && brew install mint)
	mint bootstrap
	swift package resolve $(SWIFT_FLAGS)

# --- Codegen ---

generate-code:
	mint run sourcery --quiet --config ./.sourcery.yml
	mint run sourcery --quiet --config ./.sourceryTests.yml

# --- Quality Assurance ---

lint:
	mint run swiftlint lint --quiet Sources/ Tests/
	mint run swiftformat --lint --swiftversion $(SWIFT_PACKAGE_VERSION) Sources/ Tests/

lint-fix:
	mint run swiftformat --swiftversion $(SWIFT_PACKAGE_VERSION) --config .swiftformat Sources/ Tests/
	mint run swiftlint --fix --config .swiftlint.yml --format --quiet Sources/ Tests/

# Run tests
test:
	swift test $(SWIFT_FLAGS) --parallel --enable-code-coverage -Xswiftc -warnings-as-errors

test-coverage:
	$(MAKE) test
	@XCTEST_PATH=$$(find .build -name "*.xctest" | grep "FirebladeECS" | head -n 1); \
	if [ -z "$$XCTEST_PATH" ]; then \
		echo "Could not find .xctest bundle"; \
		exit 1; \
	fi; \
	if [ "$(UNAME_S)" = "Darwin" ]; then \
		BINARY_PATH=$$(find "$$XCTEST_PATH" -type f -perm +111 | grep -v "CodeResources" | head -n 1); \
	else \
		BINARY_PATH="$$XCTEST_PATH/FirebladeECSPackageTests"; \
	fi; \
	xcrun llvm-cov report \
		"$$BINARY_PATH" \
		-instr-profile=.build/debug/codecov/default.profdata \
		-ignore-filename-regex=".build|Tests"

# Test links in README
# requires <https://github.com/tcort/markdown-link-check>
testReadme:
	markdown-link-check -p -v ./README.md

# --- Build ---

build-debug:
	swift build -c debug

build-release:
	swift build -c release --skip-update

# --- Documentation ---

docs: docs-generate

docs-preview:
	swift package --disable-sandbox preview-documentation --target FirebladeECS

docs-generate:
	mkdir -p .build/documentation/$(DOCS_VERSION_PATH)
	swift package --disable-sandbox \
		--allow-writing-to-directory .build/documentation \
		generate-documentation --target FirebladeECS \
		--disable-indexing \
		--transform-for-static-hosting \
		--hosting-base-path $(HOSTING_BASE_PATH) \
		--output-path .build/documentation/$(DOCS_VERSION_PATH)

DOCS_COVERAGE_THRESHOLD ?= 95

docs-coverage: docs-check-coverage

docs-check-coverage:
	swift package --disable-sandbox generate-documentation --target FirebladeECS --experimental-documentation-coverage --coverage-summary-level brief

docs-coverage-detailed:
	swift package --disable-sandbox generate-documentation --target FirebladeECS --experimental-documentation-coverage --coverage-summary-level detailed

docs-check-links:
	swift package --disable-sandbox generate-documentation --target FirebladeECS --analyze --warnings-as-errors

# Preview DocC documentation with analysis/warnings and overview of coverage
preview-analysis-docs:
	swift package --disable-sandbox preview-documentation --target FirebladeECS --analyze --experimental-documentation-coverage --level brief

# Generates documentation pages suitable to push/host on github pages (or another static site)
# Expected location, if set up, would be:
#   https://fireblade-engine.github.io/FirebladeECS/documentation/FirebladeECS/
generate-docs-githubpages:
	DOCC_JSON_PRETTYPRINT=YES \
	swift package \
	--allow-writing-to-directory ./docs \
	generate-documentation \
	--fallback-bundle-identifier com.github.fireblade-engine.FirebladeECS \
	--target FirebladeECS \
	--output-path ./docs \
	--transform-for-static-hosting \
	--hosting-base-path 'FirebladeECS'

# --- Workflows ---

pre-commit: lint-fix test

# --- Cleanup ---

clean: clean-sourcery
	swift package clean
	rm -rdf .build
	rm -rdf .swiftpm

clean-sourcery:
	rm -rdf ${HOME}/Library/Caches/Sourcery