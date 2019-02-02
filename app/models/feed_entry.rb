class FeedEntry

  attr_accessor :identifier, :title, :summary, :updated, :formats, :date_issued, :creators, :subjects, :publisher, :language

  def initialize(attrs={})
    attrs.each do |attr, value|
      self.send(attr.to_s + '=', value)
    end
  end
end
