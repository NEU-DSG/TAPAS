require 'rails_helper'

RSpec.describe ViewPackage, type: :model do
  it "is an ApplicationRecord" do
    expect(described_class.superclass).to eq(ApplicationRecord)
  end
end
