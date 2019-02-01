module FeedEntry
  class InternetArchive

    attr_accessor :identifier, :title, :description, :updated, :formats, :item_date, :creators, :subjects, :publisher, :language

    def initialize(attrs={})
      attrs.each do |attr, value|
        self.send(attr.to_s + '=', value)
      end
    end
  end
end
