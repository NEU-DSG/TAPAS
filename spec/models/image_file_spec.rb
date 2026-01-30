# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ImageFile, type: :model do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_presence_of(:depositor_id) }
    it { is_expected.to validate_presence_of(:image_url) }

    describe '#validate_file_format' do
      let(:image_file) { create(:image_file) }

      %w[image/jpeg image/gif image/png image/svg+xml application/pdf].each do |content_type|
        it "allows #{content_type} files" do
          image_file.file.attach(
            io: StringIO.new("file content"),
            filename: "test_file",
            content_type: content_type
          )
          image_file.valid?
          expect(image_file.errors[:image]).to be_empty
        end
      end

      it 'rejects invalid file types' do
        image_file.file.attach(
          io: StringIO.new("file content"),
          filename: "test.txt",
          content_type: "text/plain"
        )
        expect(image_file).not_to be_valid
        expect(image_file.errors[:image]).to include("must be a JPEG, GIF, PNG, SVG, or PDF file")
      end

      it 'passes validation when no file is attached' do
        image_file.valid?
        expect(image_file.errors[:image]).to be_empty
      end
    end
  end

  describe 'associations' do
    it { is_expected.to belong_to(:imageable) }
  end

  describe '#process_image_data' do
    let(:image_file) { create(:image_file) }

    it 'opens the image_url via URI' do
      fake_io = StringIO.new("image data")
      allow(URI).to receive(:open).with(image_file.image_url).and_return(fake_io)

      result = image_file.process_image_data
      expect(result).to eq(fake_io)
    end
  end
end
