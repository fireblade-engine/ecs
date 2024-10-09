SWIFT_PACKAGE_VERSION := $(shell swift package tools-version)

# Lint fix and format code.
.PHONY: lint-fix
lint-fix:
	mint run swiftlint autocorrect --format --quiet
	mint run swiftformat Sources --exclude **/*.generated.swift --swiftversion ${SWIFT_PACKAGE_VERSION}

# Generate code
.PHONY: generate-code
generate-code:
	mint run sourcery --quiet --config ./.sourcery.yml
	mint run sourcery --quiet --config ./.sourceryTests.yml

# Run pre-push tasks
.PHONY: pre-push
pre-push: generate-code lint-fix

.PHONY: setup-brew
setup-brew:
	@which -s brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	@brew update

.PHONY: install-dependencies-macOS
install-dependencies-macOS: setup-brew
	brew install mint
	mint bootstrap

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
