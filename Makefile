SWIFT_PACKAGE_VERSION := $(shell swift package tools-version)

# Lint fix and format code.
.PHONY: lint-fix
swiftlint:
	mint run swiftlint lint --fix --config .swiftlint.yml --format --quiet
swiftformat:
	mint run swiftformat . --swiftversion ${SWIFT_PACKAGE_VERSION}
lint-fix: swiftlint swiftformat

# Generate code
.PHONY: generate-code
generate-code:
	mint run sourcery --quiet --config ./.sourcery.yml
	mint run sourcery --quiet --config ./.sourceryTests.yml

# Run pre-push tasks
.PHONY: pre-push
pre-push: generate-code lint-fix

.PHONY: precommit
precommit: pre-push

.PHONY: setup-brew
setup-brew:
	@which -s brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	@brew update

.PHONY: install-dependencies-macOS
install-dependencies-macOS: setup-brew
	brew install mint
	mint bootstrap

.PHONY: setupEnvironment
setupEnvironment: install-dependencies-macOS

# Build debug version
.PHONY: build-debug
build-debug:
	swift build -c debug

# Build release version 
.PHONY: build-release
build-release:
	swift build -c release --skip-update

# Test links in README
# requires <https://github.com/tcort/markdown-link-check>
.PHONY: testReadme
testReadme:
	markdown-link-check -p -v ./README.md

# Delete package build artifacts.
.PHONY: clean
clean: clean-sourcery
	swift package clean

# Clean sourcery cache
.PHONY: clean-sourcery
clean-sourcery:
	rm -rdf ${HOME}/Library/Caches/Sourcery

# Preview DocC documentation
.PHONY: preview-docs
preview-docs:
	swift package --disable-sandbox preview-documentation --target FirebladeECS

# Preview DocC documentation with analysis/warnings and overview of coverage
.PHONY: preview-analysis-docs
preview-analysis-docs:
	swift package --disable-sandbox preview-documentation --target FirebladeECS --analyze --experimental-documentation-coverage --level brief