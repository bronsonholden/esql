require_relative 'application_record'

class Job < ApplicationRecord
  has_many :employees

  def self.migrate
    ActiveRecord::Migration.create_table(:jobs, force: true) do |t|
      t.string :title
      t.integer :base_salary
    end
  end
end
