class ImageFile < ApplicationRecord
  # associations
  belongs_to :depositor, class_name: "User"
  belongs_to :imageable, polymorphic: true
  has_one_attached :file

  # validations
  validates_presence_of :title, :depositor_id, :image_url
  validate :validate_file_format

  def process_image_data
    uri = URI.parse(image_url)
    raise ArgumentError, "URL must use http or https" unless %w[http https].include?(uri.scheme)

    addr = IPAddr.new(Resolv.getaddress(uri.host))
    raise ArgumentError, "Private or loopback URLs are not allowed" if addr.loopback? || addr.private?

    URI.open(image_url)
  rescue Resolv::ResolvError, IPAddr::InvalidAddressError
    raise ArgumentError, "Invalid or unresolvable URL"
  end

  def validate_file_format
    return unless file.attached?

    valid_types = %w[
      image/jpeg
      image/gif
      image/png
      image/svg+xml
      application/pdf
    ]

    unless file.content_type.in?(valid_types)
      errors.add(:image, "must be a JPEG, GIF, PNG, SVG, or PDF file")
    end
  end
end
