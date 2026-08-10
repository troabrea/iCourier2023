#!/usr/bin/env ruby

# Deterministically configures the single WidgetKit extension and the complete
# set of shared flavor schemes. Run from the repository root with /usr/bin/ruby.

require 'fileutils'
require 'json'
require 'xcodeproj'

project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)
runner = project.targets.find { |target| target.name == 'Runner' }
abort 'Runner target was not found' unless runner

widget = project.targets.find { |target| target.name == 'ICourierWidget' }
unless widget
  widget = project.new_target(:app_extension, 'ICourierWidget', :ios, '16.0')
  group = project.main_group.find_subpath('ICourierWidget', true)
  group.set_source_tree('<group>')
  group.set_path('ICourierWidget')
  swift = group.new_file('ICourierWidget.swift')
  group.new_file('Info.plist')
  group.new_file('ICourierWidget.entitlements')
  widget.add_file_references([swift])
  runner.add_dependency(widget)
  embed_phase = runner.new_copy_files_build_phase('Embed App Extensions')
  embed_phase.symbol_dst_subfolder_spec = :plug_ins
  build_file = embed_phase.add_file_reference(widget.product_reference, true)
  build_file.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }
end

# Flutter's Thin Binary phase reads the final app bundle. Embed extensions
# before that script to avoid a dependency cycle in Xcode's modern build graph.
embed_phase = runner.copy_files_build_phases.find do |phase|
  phase.name == 'Embed App Extensions'
end
if embed_phase
  runner.build_phases.delete(embed_phase)
  thin_index = runner.build_phases.index do |phase|
    phase.respond_to?(:name) && phase.name == 'Thin Binary'
  end
  runner.build_phases.insert(thin_index, embed_phase) if thin_index
end

# The Flutter project already owns one Runner build configuration per flavor.
# Mirror those names so the extension is built with the same selected flavor.
widget.build_configurations.dup.each do |config|
  widget.build_configuration_list.build_configurations.delete(config)
  config.remove_from_project
end
runner.build_configurations.each do |runner_config|
  name = runner_config.name
  type = name.start_with?('Debug') ? :debug : :release
  config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
  config.name = name
  widget.build_configuration_list.build_configurations << config
  base_bundle_id = runner_config.build_settings['PRODUCT_BUNDLE_IDENTIFIER']
  base_bundle_id ||= 'com.barolit.icourier'
  app_group = "group.#{base_bundle_id.downcase}"
  display_name = runner_config.build_settings['APP_DISPLAY_NAME'] || 'iCourier'
  build_number = runner_config.build_settings['CURRENT_PROJECT_VERSION'] || '1'
  marketing_version = runner_config.build_settings['MARKETING_VERSION'] || '1.0'
  config.build_settings.merge!({
    'APPLICATION_EXTENSION_API_ONLY' => 'YES',
    'APP_DISPLAY_NAME' => display_name,
    'APP_GROUP_ID' => app_group,
    'CODE_SIGN_ENTITLEMENTS' => 'ICourierWidget/ICourierWidget.entitlements',
    'CURRENT_PROJECT_VERSION' => build_number,
    'DEVELOPMENT_TEAM' => runner_config.build_settings['DEVELOPMENT_TEAM'],
    'GENERATE_INFOPLIST_FILE' => 'NO',
    'INFOPLIST_FILE' => 'ICourierWidget/Info.plist',
    'IPHONEOS_DEPLOYMENT_TARGET' => '16.0',
    'MARKETING_VERSION' => marketing_version,
    'PRODUCT_BUNDLE_IDENTIFIER' => "#{base_bundle_id}.widget",
    'PRODUCT_NAME' => '$(TARGET_NAME)',
    'SKIP_INSTALL' => 'YES',
    'SWIFT_EMIT_LOC_STRINGS' => 'YES',
    'SWIFT_VERSION' => '5.0',
    'TARGETED_DEVICE_FAMILY' => '1,2',
    'GCC_PREPROCESSOR_DEFINITIONS' => type == :debug ? ['DEBUG=1', '$(inherited)'] : ['$(inherited)'],
  }.compact)

  # App Groups are calculated from the existing bundle IDs and are therefore
  # available to the Runner entitlement for every build configuration.
  runner_config.build_settings['APP_GROUP_ID'] = app_group
  flavor = name[/^(?:Debug|Release|Profile)-(.+)$/, 1]
  config_path = flavor && File.join('whitelabel', "#{flavor}.json")
  if config_path && File.exist?(config_path)
    brand = JSON.parse(File.read(config_path))
    runner_config.build_settings['URL_SCHEME'] = brand.fetch('urlScheme', flavor)
  else
    runner_config.build_settings['URL_SCHEME'] = 'icourier'
  end
end

project.save

schemes_dir = File.join(project_path, 'xcshareddata', 'xcschemes')
FileUtils.mkdir_p(schemes_dir)
flavors = runner.build_configurations
  .map(&:name)
  .map { |name| name[/^Debug-(.+)$/, 1] }
  .compact
  .sort

template = File.read(File.join(schemes_dir, 'bmcargo.xcscheme'))
flavors.each do |flavor|
  scheme = template
    .gsub(/Debug-bmcargo/, "Debug-#{flavor}")
    .gsub(/Profile-bmcargo/, "Profile-#{flavor}")
    .gsub(/Release-bmcargo/, "Release-#{flavor}")
  File.write(File.join(schemes_dir, "#{flavor}.xcscheme"), scheme)
end

puts "Configured WidgetKit for #{runner.build_configurations.length} configurations"
puts "Configured #{flavors.length} shared flavor schemes"
