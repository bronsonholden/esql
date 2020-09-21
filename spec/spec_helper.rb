require 'simplecov'
SimpleCov.start

require 'active_record'
require 'factory_bot'
require 'bundler/setup'
require 'esql'

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

require_relative 'support/employee'
require_relative 'support/job'
require_relative 'support/project'
require_relative 'support/employee_project'

RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  # Quiet migration output
  ActiveRecord::Migration.verbose = false
  config.before(:each) do
    Employee.migrate
    Job.migrate
    Project.migrate
    EmployeeProject.migrate
  end

  config.around(:each) do |example|
    ActiveRecord::Base.transaction do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
