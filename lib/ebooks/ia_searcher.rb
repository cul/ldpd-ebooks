module Ebooks
  module IaSearcher

    IA_FIELDS = 'identifier,title,description,oai_updatedate,format,date'
    IA_SORT = 'identifier asc'

    # Note: This method can only page through up to 10,000 results because of
    # a restriction in the archive.org API. For retrieving all results for a
    # result set with over 10,000 results, you need to use the scraping API
    # (i.e. the scraping_api_search method in this class).
    def self.search(query, per_page, page)
      # Advanced Search API
      # https://archive.org/advancedsearch.php
      conn = Faraday.new(:url => 'https://archive.org')
      response = conn.get do |req|
        req.url '/advancedsearch.php'
        req.params['q'] = query
        req.params['fl'] = IA_FIELDS
        req.params['sort'] = [IA_SORT]
        req.params['rows'] = per_page
        req.params['page'] = page
        req.params['output'] = 'json'
      end

      JSON.parse(response.body)
    end

    def self.scraping_api_search(query, per_page, cursor)
      # Scraping API (with cursor)
      # See: https://archive.org/help/aboutsearch.htm
      conn = Faraday.new(:url => 'https://archive.org')
      response = conn.get do |req|
        req.url '/services/search/v1/scrape'
        req.params['q'] = query
        req.params['fields'] = IA_FIELDS
        req.params['count'] = per_page
        req.params['sorts'] = IA_SORT
        req.params['cursor'] = cursor if cursor.present?
      end

      JSON.parse(response.body)
    end

    def self.doc_to_entry(doc)
      begin
        # Dates from API are occasionally improperly formatted, so we'll catch parsing errors
        begin
          date_issued = doc['date'].present? ? DateTime.iso8601(doc['date']) : nil
        rescue ArgumentError
          date_issued = nil
        end
        begin
          updated_date = doc['oai_updatedate'].present? ? DateTime.iso8601(doc['oai_updatedate'].last) : nil
        rescue ArgumentError
          updated_date = nil
        end

        FeedEntry.new({
          identifier: doc['identifier'],
          title: doc['title'],
          summary: Array.wrap(doc['description']).join('. '),
          updated: updated_date,
          formats: doc['format'],
          date_issued: date_issued,
          creators: Array.wrap(doc['creator']),
          subjects: Array.wrap(doc['subject']),
          publisher: doc['publisher'],
          language: doc['language']
        })
      rescue ArgumentError => e
        raise "Problem parsing doc (#{e.message}): #{doc.inspect}"
        raise e # re-raise now that we've logged the error
      end
    end
  end
end
