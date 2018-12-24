#!/bin/bash

set -e 

# clean swift package
swift package clean
rm -rdf .build/

# install dependencies
bundle install
swift package update

# generate project
#   --enable-code-coverage		Enable code coverage in the generated project
#	--legacy-scheme-generator	Use the legacy scheme generator
#	--output                	Path where the Xcode project should be generated
#	--watch                 	Watch for changes to the Package manifest to regenerate the Xcode project
#	--xcconfig-overrides    	Path to xcconfig file
swift package generate-xcodeproj  --enable-code-coverage --xcconfig-overrides settings.xcconfig

# add project specialities
bundle exec ./prepareXcodeProject.rb 

# open project
open *.xcodeproj