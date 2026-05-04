FactoryBot.define do
  factory :image_file do
    sequence(:title) { |n| "Test Image #{n}" }
    association :depositor, factory: :user
    association :imageable, factory: :core_file
    image_url { "https://example.com/image.jpg" }
    file_format { "jpg" }
    description { "A test image" }
  end
end
