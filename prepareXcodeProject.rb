#!/usr/bin/env ruby

require 'xcodeproj'

path_to_project = Dir.glob('*.xcodeproj').first

project = Xcodeproj::Project.open(path_to_project)

# add build phases
project.targets.each do |target|

		puts "Add Run Shell Script Phase: Swiftlint to #{target}"
		swiftlint_phase = target.new_shell_script_build_phase("Run Swiftlint")
		swiftlint_phase.shell_script = """
set -e
if which swiftlint >/dev/null; then
	swiftlint autocorrect
	swiftlint
else
	echo 'warning: SwiftLint not installed, download from https://github.com/realm/SwiftLint'
fi
"""

end

project.save()