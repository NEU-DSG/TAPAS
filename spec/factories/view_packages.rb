FactoryBot.define do
  factory :view_package do
    sequence(:human_name) { |n| "View Package #{n}" }
    sequence(:machine_name) { |n| "view_package_#{n}" }
  end
end
