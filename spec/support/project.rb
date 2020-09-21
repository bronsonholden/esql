require_relative 'application_record'

class Project < ApplicationRecord
  has_many :employees, through: :employee_project

  def self.migrate
    ActiveRecord::Migration.create_table(:projects, force: true) do |t|
      t.string :name
    end
  end
end
