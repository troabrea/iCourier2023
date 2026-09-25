#!/usr/bin/env ruby

require 'json'
require 'optparse'
require 'xcodeproj'

options = { root: Dir.pwd, template: 'brodpaq', apply: false }
OptionParser.new do |parser|
  parser.banner = 'Usage: configure_ios_flavor.rb --manifest FILE [--apply]'
  parser.on('--manifest FILE') { |value| options[:manifest] = value }
  parser.on('--root DIR') { |value| options[:root] = value }
  parser.on('--template SLUG') { |value| options[:template] = value }
  parser.on('--apply') { options[:apply] = true }
end.parse!

abort 'Missing --manifest' unless options[:manifest]
root = File.expand_path(options[:root])
manifest = JSON.parse(File.read(File.expand_path(options[:manifest])))
slug = manifest.fetch('slug')
name = manifest.fetch('name')
bundle_id = manifest.fetch('bundleId')
app_group = manifest.fetch('appGroup')
url_scheme = manifest.fetch('urlScheme')
team = manifest.fetch('iosTeam')
version = manifest.fetch('version')
build = manifest.fetch('build').to_s
project_path = File.join(root, 'ios', 'Runner.xcodeproj')
project = Xcodeproj::Project.open(project_path)
runner = project.targets.find { |target| target.name == 'Runner' }
widget = project.targets.find { |target| target.name == 'ICourierWidget' }
abort 'Runner target was not found' unless runner
abort 'ICourierWidget target was not found' unless widget

configuration_names = %w[Debug Profile Release].map { |type| "#{type}-#{slug}" }
present = {
  'project' => project.build_configurations.map(&:name) & configuration_names,
  'runner' => runner.build_configurations.map(&:name) & configuration_names,
  'widget' => widget.build_configurations.map(&:name) & configuration_names,
}
scheme_path = File.join(project_path, 'xcshareddata', 'xcschemes', "#{slug}.xcscheme")

unless options[:apply]
  puts JSON.pretty_generate(
    slug: slug,
    mode: 'plan',
    configurations: configuration_names,
    present: present,
    scheme: File.exist?(scheme_path) ? 'present' : 'missing',
  )
  exit
end

def copy_configuration(project, list, source_name, target_name)
  existing = list.build_configurations.find { |config| config.name == target_name }
  return existing if existing

  source = list.build_configurations.find { |config| config.name == source_name }
  abort "Template configuration #{source_name} was not found" unless source
  config = project.new(Xcodeproj::Project::Object::XCBuildConfiguration)
  config.name = target_name
  config.base_configuration_reference = source.base_configuration_reference
  config.build_settings = Marshal.load(Marshal.dump(source.build_settings))
  list.build_configurations << config
  config
end

%w[Debug Profile Release].each do |type|
  source_name = "#{type}-#{options[:template]}"
  target_name = "#{type}-#{slug}"
  copy_configuration(
    project,
    project.build_configuration_list,
    source_name,
    target_name,
  )
  runner_config = copy_configuration(
    project,
    runner.build_configuration_list,
    source_name,
    target_name,
  )
  widget_config = copy_configuration(
    project,
    widget.build_configuration_list,
    source_name,
    target_name,
  )

  runner_config.build_settings.merge!({
    'APP_DISPLAY_NAME' => name,
    'APP_GROUP_ID' => app_group,
    'ASSETCATALOG_COMPILER_APPICON_NAME' => "AppIcon-#{slug}",
    'ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME' => '',
    'CURRENT_PROJECT_VERSION' => build,
    'DEVELOPMENT_TEAM' => team,
    'INFOPLIST_KEY_UILaunchStoryboardName' => "LaunchScreen#{slug.capitalize}.storyboard",
    'LAUNCH_SCREEN_STORYBOARD' => "LaunchScreen#{slug.capitalize}",
    'MARKETING_VERSION' => version,
    'PRODUCT_BUNDLE_IDENTIFIER' => bundle_id,
    'URL_SCHEME' => url_scheme,
  })
  widget_config.build_settings.merge!({
    'APP_DISPLAY_NAME' => name,
    'APP_GROUP_ID' => app_group,
    'CURRENT_PROJECT_VERSION' => build,
    'DEVELOPMENT_TEAM' => team,
    'MARKETING_VERSION' => version,
    'PRODUCT_BUNDLE_IDENTIFIER' => "#{bundle_id}.widget",
  })
end

project.save

unless File.exist?(scheme_path)
  template_path = File.join(
    project_path,
    'xcshareddata',
    'xcschemes',
    "#{options[:template]}.xcscheme",
  )
  scheme = File.read(template_path)
    .gsub("Debug-#{options[:template]}", "Debug-#{slug}")
    .gsub("Profile-#{options[:template]}", "Profile-#{slug}")
    .gsub("Release-#{options[:template]}", "Release-#{slug}")
  File.write(scheme_path, scheme)
end

# The splash generator creates the localized storyboard on disk but does not
# register a new flavor's storyboard with Xcode. Register it once it exists;
# reruns leave both the variant group and resources phase untouched.
storyboard_name = "LaunchScreen#{slug.capitalize}.storyboard"
storyboard_path = File.join(root, 'ios', 'Runner', 'Base.lproj', storyboard_name)
if File.exist?(storyboard_path)
  runner_group = project.main_group.find_subpath('Runner', false)
  abort 'Runner group was not found' unless runner_group
  variant_group = runner_group.children.find do |child|
    child.display_name == storyboard_name
  end
  unless variant_group
    variant_group = runner_group.new_variant_group(storyboard_name)
    base = variant_group.new_file(File.join('Base.lproj', storyboard_name))
    base.name = 'Base'
  end
  unless runner.resources_build_phase.files_references.include?(variant_group)
    runner.resources_build_phase.add_file_reference(variant_group, true)
  end
  project.save
end

puts JSON.pretty_generate(slug: slug, mode: 'apply', configurations: configuration_names)
