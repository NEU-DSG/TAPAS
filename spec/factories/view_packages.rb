FactoryBot.define do
  factory :view_package do
    sequence(:machine_name) { |n| "view_package_#{n}" }
    sequence(:human_name) { |n| "View Package #{n}" }
    description { "A test view package" }
    dir_name { "test_dir" }
    file_type { "xslt" }
    git_branch { "main" }
  end
end
