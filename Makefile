UNAME_S := $(shell uname -s)
SWIFT_FLAGS ?= --disable-sandbox
SWIFT_PACKAGE_VERSION := $(shell swift package tools-version)

ifdef GEMINI_CLI
XCS_FORMATTER = 2>&1 | mint run xcsift -w -W -c -f toon
endif

# Repository name on GitHub Pages
REPO_NAME ?= ecs
# Subdirectory for versioned documentation (e.g., main, 1.0.0)
DOCS_VERSION_PATH ?= main

# The full base path for hosting
HOSTING_BASE_PATH ?= $(REPO_NAME)/$(DOCS_VERSION_PATH)

.PHONY: setup lint lint-fix test test-coverage testReadme build-debug build-release docs docs-preview docs-generate docs-generate-all docs-coverage docs-check-coverage docs-check-links preview-analysis-docs generate-docs-githubpages pre-commit clean benchmark benchmark-compare benchmark-report test-benchmarks test-benchmark-scripts

# --- Setup ---

setup:
	@which -s brew || /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
	@brew update
	@echo "Detected Package Swift Version: $(SWIFT_PACKAGE_VERSION)"
	@which mint > /dev/null || (echo "Mint not found. Installing via Homebrew..." && brew install mint)
	mint bootstrap
	swift package resolve $(SWIFT_FLAGS)

# --- Quality Assurance ---

lint:
	mint run swiftlint lint --quiet Sources/ Tests/
	mint run swiftformat --lint --config .swiftformat --swiftversion $(SWIFT_PACKAGE_VERSION) Sources/ Tests/

lint-fix:
	mint run swiftformat --swiftversion $(SWIFT_PACKAGE_VERSION) --config .swiftformat Sources/ Tests/
	mint run swiftlint --fix --config .swiftlint.yml --format --quiet Sources/ Tests/

# Run tests
test:
	swift test $(SWIFT_FLAGS) --parallel --enable-code-coverage -Xswiftc -warnings-as-errors $(XCS_FORMATTER)

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
	swift build -c debug $(XCS_FORMATTER)

build-release:
	swift build -c release --skip-update $(XCS_FORMATTER)

# --- Documentation ---

docs: docs-generate

docs-preview:
	swift package --disable-sandbox preview-documentation --target FirebladeECS

docs-generate:
	./Scripts/sync-documentation.sh

docs-backfill-tags:
	./Scripts/backfill-doc-tags.sh

DOCS_COVERAGE_THRESHOLD ?= 95

# Documented targets; FirebladeFSM is the optional state machine product.
DOCS_TARGETS ?= FirebladeECS FirebladeFSM

docs-coverage: docs-check-coverage

docs-check-coverage:
	for target in $(DOCS_TARGETS); do \
		swift package --disable-sandbox generate-documentation --target $$target --experimental-documentation-coverage --coverage-summary-level brief $(XCS_FORMATTER) || exit 1; \
	done

docs-coverage-detailed:
	for target in $(DOCS_TARGETS); do \
		swift package --disable-sandbox generate-documentation --target $$target --experimental-documentation-coverage --coverage-summary-level detailed $(XCS_FORMATTER) || exit 1; \
	done

docs-check-links:
	for target in $(DOCS_TARGETS); do \
		swift package --disable-sandbox generate-documentation --target $$target --analyze --warnings-as-errors $(XCS_FORMATTER) || exit 1; \
	done

# Preview DocC documentation with analysis/warnings and overview of coverage
preview-analysis-docs:
	swift package --disable-sandbox preview-documentation --target FirebladeECS --analyze --experimental-documentation-coverage --level brief

# Generates documentation pages suitable to push/host on github pages (or another static site)
# Expected location, if set up, would be:
#   https://fireblade-engine.github.io/ecs/ -> https://fireblade-engine.github.io/ecs/main/documentation/firebladeecs/
generate-docs-githubpages:
	DOCC_JSON_PRETTYPRINT=YES \
	swift package \
	--allow-writing-to-directory ./docs \
	generate-documentation \
	--fallback-bundle-identifier com.github.fireblade-engine.FirebladeECS \
	--target FirebladeECS \
	--output-path ./docs \
	--transform-for-static-hosting \
	--hosting-base-path '$(REPO_NAME)'

# --- Benchmarks ---

BENCHMARK_FILTER ?=
REPORT_OUTPUT ?= Benchmarks/.results/report.md
REPORT_BASELINE ?=
REPORT_TITLE ?=
RESULTS_TOOL = Benchmarks/.build/release/ECSBenchmarkResults

# Runtime benchmarks live in a separate package (Benchmarks/) so the benchmark dependency stays out of FirebladeECS.
benchmark:
	cd Benchmarks && swift package benchmark

# Measures the shared compatibility suite at each committed ref (comma-separated tags, branches or SHAs) in isolated
# snapshots and saves one validated result file per ref under Benchmarks/.results/<UTC timestamp>/.
# Without BENCHMARK_FILTER only the smallest scale of every workload runs; BENCHMARK_FILTER='.*' selects everything.
benchmark-compare:
	@if [ -z "$(REFS)" ]; then printf 'Set REFS to comma-separated Git refs, for example: make benchmark-compare REFS=1.4.3,main\n' >&2; exit 2; fi
	./Scripts/benchmark-run-refs.sh --refs "$(REFS)" $(if $(BENCHMARK_FILTER),--filter "$(BENCHMARK_FILTER)")

# Renders a Markdown report from saved result files only (at least two); it never runs benchmarks.
benchmark-report:
	@if [ -z "$(RESULTS)" ]; then printf 'Set RESULTS to saved result files, for example: make benchmark-report RESULTS="a.json b.json"\n' >&2; exit 2; fi
	swift build --package-path Benchmarks -c release --product ECSBenchmarkResults $(SWIFT_FLAGS)
	$(RESULTS_TOOL) report $(RESULTS) --output "$(REPORT_OUTPUT)" $(if $(REPORT_BASELINE),--baseline "$(REPORT_BASELINE)") $(if $(REPORT_TITLE),--title "$(REPORT_TITLE)")

test-benchmarks:
	cd Benchmarks && swift test $(SWIFT_FLAGS)

test-benchmark-scripts:
	./Tests/benchmark-snapshot-tests.sh
	./Tests/benchmark-run-refs-tests.sh

# --- Workflows ---

pre-commit: lint-fix test

# --- Cleanup ---

clean:
	swift package clean
	rm -rdf .build
	rm -rdf .swiftpm