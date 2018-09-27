#!/bin/bash

set -e 

# clean swift package
swift package clean
rm -rdf .build/

# install dependencies
bundle install
swift package update

# generate project
swift package generate-xcodeproj --enable-code-coverage #--xcconfig-overrides settings.xcconfig

# add project specialities
bundle exec ./prepareXcodeProject.rb 

# open project
open *.xcodeproj