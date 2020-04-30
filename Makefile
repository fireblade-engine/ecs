# Version 1.0.0
UNAME_S := $(shell uname -s)

# Lint
lint:
	swiftlint autocorrect --format
	swiftlint lint --quiet

lintErrorOnly:
	@swiftlint autocorrect --format --quiet
	@swiftlint lint --quiet | grep error

# Git
precommit: lint genLinuxTests

submodule:
	git submodule init
	git submodule update --recursive

# Tests
genLinuxTests:
	swift test --generate-linuxmain
	swiftlint autocorrect --format --path Tests/

test: genLinuxTests
	swift test

# Package
latest:
	swift package update

resolve:
	swift package resolve

# Xcode
genXcode:
	swift package generate-xcodeproj --enable-code-coverage --skip-extra-files

genXcodeOpen: genXcode
	open *.xcodeproj

# Clean
clean:
	swift package reset
	rm -rdf .swiftpm/xcode
	rm -rdf .build/
	rm Package.resolved
	rm .DS_Store

cleanArtifacts:
	swift package clean

# Test links in README
# requires <https://github.com/tcort/markdown-link-check>
testReadme:
	markdown-link-check -p -v ./README.md