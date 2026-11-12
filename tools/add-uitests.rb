#!/usr/bin/env ruby
# Adds the MyCoinsUITests target to ios/MyCoins.xcodeproj and to the MyCoins
# scheme's test action. Already run once — the target is in the project. Kept
# for the day the project file is regenerated from the React Native template.
#
#   ruby tools/add-uitests.rb
require 'xcodeproj'

root = File.expand_path('../ios', __dir__)
project = Xcodeproj::Project.open(File.join(root, 'MyCoins.xcodeproj'))
tests = project.targets.find { |t| t.name == 'MyCoinsUITests' }
app = project.targets.find { |t| t.name == 'MyCoins' }
unless tests
tests = project.new_target(:ui_test_bundle, 'MyCoinsUITests', :ios, '15.1', nil, :swift)
group = project.main_group.new_group('MyCoinsUITests', 'MyCoinsUITests')
tests.add_file_references([group.new_file('WalkthroughTests.swift')])
tests.add_dependency(app)
tests.build_configurations.each do |c|
  s = c.build_settings
  s['TEST_TARGET_NAME'] = 'MyCoins'
  s['PRODUCT_NAME'] = '$(TARGET_NAME)'
  s['PRODUCT_BUNDLE_IDENTIFIER'] = 'com.mycoins.wallet.ios.uitests'
  s['GENERATE_INFOPLIST_FILE'] = 'YES'
  s['SWIFT_VERSION'] = '5.0'
  s['DEVELOPMENT_TEAM'] = '5768V787GP'
  s['CODE_SIGN_STYLE'] = 'Automatic'
  s['TARGETED_DEVICE_FAMILY'] = '1'
end
project.save
end

path = File.join(root, 'MyCoins.xcodeproj/xcshareddata/xcschemes/MyCoins.xcscheme')
scheme = Xcodeproj::XCScheme.new(path)
# The template's scheme still names a MyCoinsTests target that does not exist.
scheme.test_action.xml_element.elements.delete_all('Testables/TestableReference')
scheme.add_test_target(tests)
# A Release build carries its JavaScript, so the walkthrough needs no Metro.
scheme.test_action.build_configuration = 'Release'
scheme.save_as(File.join(root, 'MyCoins.xcodeproj'), 'MyCoins', true)
