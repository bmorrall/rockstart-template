# frozen_string_literal: true

require 'bundler'
require 'json'
RAILS_REQUIREMENT = '~> 6.1.0'

# require 'active_record/migration'
require 'rails/generators/active_record/migration'

module MigrationHelpers
  # Implement the required interface for Rails::Generators::Migration.
  def next_migration_number(_dirname)
    @next_migration_number ||= Time.now.utc
    @next_migration_number += 1
    @next_migration_number.strftime('%Y%m%d%H%M%S')
  end
end

extend Rails::Generators::Migration
self.class.extend Rails::Generators::Migration::ClassMethods
self.class.extend MigrationHelpers

# Setup code copied from https://github.com/mattbrictson/rails-template

def apply_template!
  assert_minimum_rails_version
  assert_valid_options
  assert_postgresql

  add_template_repository_to_source_path

  # We're going to handle bundler and webpacker ourselves.
  # Setting these options will prevent Rails from running them unnecessarily.
  self.options = options.merge(
    skip_bundle: true,
    skip_webpack_install: true
  )

  template 'Gemfile.tt', force: true

  apply 'Rakefile.rb'

  template 'env.test', '.env.test'

  add_rspec_install
  directory 'app'
  directory 'config'
  directory 'lib'
  directory 'spec'

  git :init unless preexisting_git_repo?
  empty_directory '.git/safe'

  copy_file 'gitignore', '.gitignore', force: true

  run_with_clean_bundler_env 'bundle update'
  create_database
  migration_template 'db/migrate/devise_create_users.rb', 'db/migrate/devise_create_users.rb'
  run_with_clean_bundler_env 'bin/setup'

  binstubs = %w[brakeman bundler bundler-audit rspec-core rubocop]
  run_with_clean_bundler_env "bundle binstubs #{binstubs.join(' ')} --force"

  template 'rubocop.yml.tt', '.rubocop.yml'
  run_rubocop_autocorrections

  add_heroku_configuration

  unless any_local_git_commits?
    git checkout: '-b main'
    git add: '-A .'
    git commit: "-n -m 'Initial commit'"
  end
end

def assert_minimum_rails_version
  requirement = Gem::Requirement.new(RAILS_REQUIREMENT)
  rails_version = Gem::Version.new(Rails::VERSION::STRING)
  return if requirement.satisfied_by?(rails_version)

  prompt = "This template requires Rails #{RAILS_REQUIREMENT}. "\
           "You are using #{rails_version}. Continue anyway?"
  exit 1 if no?(prompt)
end

# Bail out if user has passed in contradictory generator options.
def assert_valid_options
  valid_options = {
    skip_gemfile: false,
    skip_bundle: false,
    skip_git: false,
    skip_system_test: false,
    skip_test: true,
    skip_test_unit: false,
    edge: false
  }
  valid_options.each do |key, expected|
    next unless options.key?(key)

    actual = options[key]
    raise Rails::Generators::Error, "Unsupported option: #{key}=#{actual}" unless actual == expected
  end
end

def assert_postgresql
  return if IO.read('Gemfile') =~ /^\s*gem ['"]pg['"]/

  raise Rails::Generators::Error, 'This template requires PostgreSQL, but the pg gem isn’t present in your Gemfile.'
end

require 'fileutils'
require 'shellwords'

# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require 'tmpdir'
    source_paths.unshift(tempdir = Dir.mktmpdir('rails-template-'))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      '--quiet',
      'https://github.com/bmorrall/rockstart-template.git',
      tempdir
    ].map(&:shellescape).join(' ')

    if (branch = __FILE__[%r{rockstart-template/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def gemfile_requirement(name)
  @original_gemfile ||= IO.read('Gemfile')
  req = @original_gemfile[/gem\s+['"]#{name}['"]\s*(,[><~= \t\d.\w'"]*)?.*$/, 1]
  req && req.gsub("'", %(")).strip.sub(/^,\s*"/, ', "').gsub('"', "'")
end

def preexisting_git_repo?
  @preexisting_git_repo ||= (File.exist?('.git') || :nope)
  @preexisting_git_repo == true
end

def any_local_git_commits?
  system('git log > /dev/null 2>&1')
end

def run_with_clean_bundler_env(cmd)
  success = if defined?(Bundler)
              if Bundler.respond_to?(:with_unbundled_env)
                Bundler.with_unbundled_env { run(cmd) }
              else
                Bundler.with_clean_env { run(cmd) }
              end
            else
              run(cmd)
            end
  return if success

  puts "Command failed, exiting: #{cmd}"
  exit(1)
end

def create_database
  return if Dir['db/migrate/**/*.rb'].any?

  run_with_clean_bundler_env 'bin/rails db:create'
end

def run_rubocop_autocorrections
  run_with_clean_bundler_env 'bin/rubocop -A --fail-level A > /dev/null || true'
end

def sprockets?
  !options[:skip_sprockets]
end

def add_rspec_install
  template 'rspec', '.rspec'
  directory 'spec'
end

def add_heroku_configuration
  run_with_clean_bundler_env 'bundle lock --add-platform x86_64-linux'
end

apply_template!
