require_relative 'application_record'
require_relative 'job'

class Employee < ApplicationRecord
  belongs_to :job
  has_many :projects, through: :employee_project

  def self.migrate
    ActiveRecord::Migration.create_table(:employees, force: true) do |t|
      t.string :first_name
      t.string :last_name
      t.references :job
      t.datetime :dob
    end
  end
end
