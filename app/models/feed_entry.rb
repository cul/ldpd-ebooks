class FeedEntry

  attr_accessor :identifier, :title, :summary, :updated, :formats, :date_issued, :creators, :subjects, :publisher, :language

  def initialize(attrs={})
    attrs.each do |attr, value|
      self.send(attr.to_s + '=', value)
    end
  end

  def has_pdf?
    formats.detect{ |f| f =~ /pdf/i}
  end

  def has_epub?
    formats.include?('Abbyy GZ')
  end

  def has_image?
    (['JPEG Thumb', 'Item Tile', 'Animated GIF'] & formats).present?
  end
end
