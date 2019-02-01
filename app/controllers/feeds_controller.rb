class FeedsController < ApplicationController

  IA_FIELDS = 'identifier,title,description,oai_updatedate,format,date'
  IA_SORT = 'identifier asc'
  IA_QUERY = 'collection:ColumbiaUniversityLibraries'

  def index
    # just redirecting for now. will have a more useful index later.
    redirect_to action: 'ia'
    return
  end

  def ia
    @page = params.fetch(:page, 1).to_i
    @per_page = 20

    # Regular API
    conn = Faraday.new(:url => 'https://archive.org')
    response = conn.get do |req|
      req.url '/advancedsearch.php'
      req.params['q'] = IA_QUERY
      req.params['fl'] = IA_FIELDS
      req.params['sort'] = [IA_SORT]
      req.params['rows'] = @per_page
      req.params['page'] = @page
      req.params['output'] = 'json'
    end

    data = JSON.parse(response.body)
    @entries = data['response']['docs'].map do |doc|
      entry_for_ia_doc(doc)
    end
  end

  def ia_crawlable
    @per_page = 1000 # must be at least 100 for the Scrape API
    cursor = params[:cursor]

    # Scrape API (with cursor)
    conn = Faraday.new(:url => 'https://archive.org')
    response = conn.get do |req|
      req.url '/services/search/v1/scrape'
      req.params['q'] = IA_QUERY
      req.params['fields'] = IA_FIELDS
      req.params['count'] = @per_page
      req.params['sorts'] = IA_SORT
      req.params['cursor'] = cursor if cursor.present?
    end
    data = JSON.parse(response.body)
    @next_cursor = data['cursor']
    @more_results_available = data['total'] > 0
    @entries = data['items'].map do |doc|
      entry_for_ia_doc(doc)
    end
  end

  private

  def entry_for_ia_doc(doc)
    begin
      # Dates from API are occasionally improperly formatted, so we'll catch parsing errors
      begin
        item_date = doc['date'].present? ? DateTime.iso8601(doc['date']) : nil
      rescue ArgumentError
        item_date = nil
      end
      begin
        updated_date = doc['oai_updatedate'].present? ? DateTime.iso8601(doc['oai_updatedate'].last) : nil
      rescue ArgumentError
        updated_date = nil
      end

      FeedEntry::InternetArchive.new({
        identifier: doc['identifier'],
        title: doc['title'],
        description: Array.wrap(doc['description']).join('. '),
        updated: updated_date,
        formats: doc['format'],
        item_date: item_date,
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
