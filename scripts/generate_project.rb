#!/usr/bin/env ruby

require "xcodeproj"
require "fileutils"

root = File.expand_path("..", __dir__)
project_path = File.join(root, "MigMouse.xcodeproj")
FileUtils.rm_rf(project_path)

project = Xcodeproj::Project.new(project_path)
project.root_object.attributes["LastSwiftUpdateCheck"] = "2660"
project.root_object.attributes["LastUpgradeCheck"] = "2660"

app = project.new_target(:application, "MigMouse", :osx, "14.0")
tests = project.new_target(:unit_test_bundle, "MigMouseTests", :osx, "14.0")
tests.add_dependency(app)

app_group = project.main_group.new_group("MigMouse", "MigMouse")
test_group = project.main_group.new_group("MigMouseTests", "MigMouseTests")

source_extensions = %w[.swift .m]
Dir.glob(File.join(root, "MigMouse", "**", "*"), File::FNM_DOTMATCH).sort.each do |path|
  next unless File.file?(path)
  relative = path.delete_prefix(File.join(root, "MigMouse") + "/")
  reference = app_group.new_file(relative)
  app.add_file_references([reference]) if source_extensions.include?(File.extname(path))
end

localization_group = app_group.new_group("Localization", "Localization")
strings_variant = localization_group.new_variant_group("Localizable.strings")
locales = %w[en zh-Hans zh-Hant ja ko fr de es pt-BR it ru ar]
locales.each do |locale|
  strings_variant.new_file("#{locale}.lproj/Localizable.strings")
end
app.resources_build_phase.add_file_reference(strings_variant)
project.root_object.known_regions = locales + ["Base"]

Dir.glob(File.join(root, "MigMouseTests", "**", "*.swift")).sort.each do |path|
  relative = path.delete_prefix(File.join(root, "MigMouseTests") + "/")
  reference = test_group.new_file(relative)
  tests.add_file_references([reference])
end

frameworks = project.frameworks_group
%w[AppKit.framework ApplicationServices.framework CoreGraphics.framework Foundation.framework SwiftUI.framework].each do |name|
  ref = frameworks.new_file("System/Library/Frameworks/#{name}")
  ref.source_tree = "SDKROOT"
  app.frameworks_build_phase.add_file_reference(ref)
end

app.build_configurations.each do |config|
  settings = config.build_settings
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.zhouxingbang.MigMouse"
  settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  settings["INFOPLIST_FILE"] = "MigMouse/Supporting/Info.plist"
  settings["CODE_SIGN_ENTITLEMENTS"] = "MigMouse/Supporting/MigMouse.entitlements"
  settings["SWIFT_OBJC_BRIDGING_HEADER"] = "MigMouse/Supporting/MigMouse-Bridging-Header.h"
  settings["SWIFT_VERSION"] = "5.0"
  settings["CLANG_ENABLE_MODULES"] = "YES"
  settings["CLANG_ENABLE_OBJC_ARC"] = "YES"
  settings["ENABLE_APP_SANDBOX"] = "NO"
  settings["ENABLE_HARDENED_RUNTIME"] = "YES"
  settings["LD_RUNPATH_SEARCH_PATHS"] = "$(inherited) @executable_path/../Frameworks"
  settings["MACOSX_DEPLOYMENT_TARGET"] = "14.0"
end

tests.build_configurations.each do |config|
  settings = config.build_settings
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "com.zhouxingbang.MigMouseTests"
  settings["GENERATE_INFOPLIST_FILE"] = "YES"
  settings["SWIFT_VERSION"] = "5.0"
  settings["MACOSX_DEPLOYMENT_TARGET"] = "14.0"
  settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/MigMouse.app/Contents/MacOS/MigMouse"
  settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
end

project.save

scheme = Xcodeproj::XCScheme.new
scheme.configure_with_targets(app, app)
scheme.add_test_target(tests)
scheme.save_as(project_path, "MigMouse", true)
