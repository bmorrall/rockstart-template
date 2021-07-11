# frozen_string_literal: true

task :security_audit do
  def system!(*args)
    system(*args) || abort("\n== Command #{args} failed ==")
  end

  puts "Running Brakeman..."
  system! 'bundle exec brakeman -q --no-summary'

  puts "Running bundle-audit..."
  system! 'bundle exec bundle-audit check --update -v'
end
