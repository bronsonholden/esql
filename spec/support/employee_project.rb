require_relative 'application_record'
require_relative 'employee'
require_relative 'project'

class EmployeeProject < ApplicationRecord
  belongs_to :employee
  belongs_to :project

  def self.migrate
    ActiveRecord::Migration.create_table(:employee_projects, force: true) do |t|
      t.references :employees
      t.references :projects
    end
  end
end
