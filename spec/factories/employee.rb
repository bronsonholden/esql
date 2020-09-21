FactoryBot.define do
  factory :employee do
    first_name { 'John' }
    last_name { 'Doe' }
    dob { DateTime.new(1980, 1, 1) }
  end
end
