lint:
	swiftlint autocorrect --format
	swiftlint lint --quiet

genLinuxTests:
	swift test --generate-linuxmain
	swiftlint autocorrect --format --path Tests/

test: genLinuxTests
	swift test

clean:
	swift package reset
	rm -rdf .swiftpm/xcode
	rm -rdf .build/
	rm Package.resolved
	rm .DS_Store

cleanArtifacts:
	swift package clean

genXcode:
	swift package generate-xcodeproj --enable-code-coverage --skip-extra-files

latest:
	swift package update

resolve:
	swift package resolve

genXcodeOpen: genXcode
	open *.xcodeproj

precommit: lint genLinuxTests

testReadme:
	markdown-link-check -p -v ./README.md
