# frozen_string_literal: true

append_to_file 'Rakefile' do
  <<~RUBY
    Rake::Task[:default].prerequisites.clear if Rake::Task.task_defined?(:default)
    task :default do
      sh 'bin/rspec'
      raise unless
        system('bin/rake security_audit') &
        system('bin/rubocop')
    end
  RUBY
end
