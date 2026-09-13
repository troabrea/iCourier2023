#!/usr/bin/env ruby
# Plans version changes by default. Never builds or uploads binaries.
require 'json'
require 'optparse'
require 'pathname'
require 'rexml/document'
require 'xcodeproj'

options = { ios: [], android: [], apply: false, root: Dir.pwd }
parser = OptionParser.new do |p|
  p.banner = 'prepare_release.rb --ios bmcargo,tupaq --android tupaq [--version X.Y.Z] [--apply]'
  p.on('--ios COURIERS', Array) { |v| options[:ios] = v.map(&:downcase).uniq }
  p.on('--android COURIERS', Array) { |v| options[:android] = v.map(&:downcase).uniq }
  p.on('--version VERSION', 'Optional explicit marketing version X.Y.Z') { |v| options[:version] = v }
  p.on('--root PATH') { |v| options[:root] = v }
  p.on('--apply', 'Write the planned version changes; does not build') { options[:apply] = true }
end
begin
  parser.parse!
  raise 'Unexpected positional arguments' unless ARGV.empty?
  raise 'Specify --ios and/or --android' if options[:ios].empty? && options[:android].empty?
  root = Pathname.new(options[:root]).realpath
  pubspec_path = root.join('pubspec.yaml')
  pubspec = pubspec_path.read
  version_match = pubspec.match(/^version: (\d+\.\d+\.\d+)\+(\d+)\s*$/)
  raise 'Expected version: X.Y.Z+N in pubspec.yaml' unless version_match
  old_version, old_build = version_match.captures
  version = options[:version]
  raise 'Version must be X.Y.Z' if version && !version.match?(/\A\d+\.\d+\.\d+\z/)
  registry = JSON.parse(root.join('tools/android_releases.json').read)
  # Resolve the actual entrypoint instead of assuming the flavor directory name.
  entrypoints = {}
  (options[:ios] + options[:android]).uniq.each do |slug|
    raise "Invalid courier: #{slug}" unless slug.match?(/\A[a-z0-9]+\z/)
    raise "Missing whitelabel: #{slug}" unless root.join("whitelabel/#{slug}.json").file?
    matches = Dir.glob(root.join("lib/apps/**/main_#{slug == 'picknsend' ? 'pns' : slug}.dart").to_s)
    raise "Ambiguous/missing entrypoint for #{slug}" unless matches.length == 1
    entrypoints[slug] = Pathname.new(matches.first).relative_path_from(root).to_s
  end
  project = options[:ios].empty? ? nil : Xcodeproj::Project.open(root.join('ios/Runner.xcodeproj'))
  selected = []
  ios_rows = options[:ios].map do |slug|
    scheme = root.join("ios/Runner.xcodeproj/xcshareddata/xcschemes/#{slug}.xcscheme")
    raise "Missing release scheme for #{slug}" unless scheme.file? && REXML::Document.new(scheme.read).elements['Scheme/ArchiveAction']&.attributes&.[]('buildConfiguration') == "Release-#{slug}"
    configs = %w[Runner ICourierWidget].map do |name|
      target = project.targets.find { |t| t.name == name }
      config = target&.build_configurations&.find { |c| c.name == "Release-#{slug}" }
      raise "Missing #{name}/Release-#{slug}" unless config
      selected << config
      config
    end
    settings = configs.map(&:build_settings)
    raise "App/widget versions differ for #{slug}" unless settings.map { |s| [s['MARKETING_VERSION'], s['CURRENT_PROJECT_VERSION']] }.uniq.length == 1
    current_version = settings.first.fetch('MARKETING_VERSION')
    current_build = settings.first.fetch('CURRENT_PROJECT_VERSION')
    raise "Non-integer iOS build for #{slug}" unless current_build.match?(/\A\d+\z/)
    raise "Version downgrade for #{slug}" if version && (version.split('.').map(&:to_i) <=> current_version.split('.').map(&:to_i)) == -1
    { courier: slug, entrypoint: entrypoints[slug], bundleId: settings.first.fetch('PRODUCT_BUNDLE_IDENTIFIER'), from: "#{current_version}+#{current_build}", version: version || current_version }
  end
  ios_build = if selected.empty?
                old_build.to_i
              else
                ([old_build.to_i] + selected.map { |c| c.build_settings.fetch('CURRENT_PROJECT_VERSION').to_i }).max + 1
              end
  ios_rows.each { |row| row[:build] = ios_build }
  android_path = root.join('android/release.properties')
  android_text = android_path.read
  old_code = android_text[/^versionCode=(\d+)$/, 1]
  raise 'Missing Android versionCode' unless old_code
  code = old_code.to_i + (options[:android].empty? ? 0 : 1)
  raise 'Android versionCode exceeds Play limit' if code > 2_100_000_000
  raise 'Version downgrade in pubspec.yaml' if version && (version.split('.').map(&:to_i) <=> old_version.split('.').map(&:to_i)) == -1
  android_rows = options[:android].map do |slug|
    record = registry.fetch(slug)
    last = record['lastPublishedVersionCode']
    raise "Android code must exceed confirmed published code for #{slug}" if last && code <= last
    { courier: slug, entrypoint: entrypoints[slug], applicationId: record.fetch('applicationId'), version: version || old_version, fromCode: old_code.to_i, code: code }
  end
  plan = { mode: options[:apply] ? 'apply' : 'plan', pubspec: { from: "#{old_version}+#{old_build}", to: "#{version || old_version}+#{ios_build}" }, ios: ios_rows, android: android_rows }
  if options[:apply]
    # All input checks complete before touching any release configuration.
    selected.each do |config|
      config.build_settings['CURRENT_PROJECT_VERSION'] = ios_build.to_s
      config.build_settings['MARKETING_VERSION'] = version if version
    end
    project.save if project
    pubspec_path.write(pubspec.sub(/^version: \d+\.\d+\.\d+\+\d+/, "version: #{version || old_version}+#{ios_build}"))
    android_path.write(android_text.sub(/^versionCode=\d+$/, "versionCode=#{code}")) unless options[:android].empty?
  end
  puts JSON.pretty_generate(plan)
rescue StandardError => e
  warn "Release preparation failed: #{e.message}"
  exit 1
end
