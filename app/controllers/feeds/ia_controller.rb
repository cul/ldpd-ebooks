module Feeds
  class IaController < ApplicationController

    MAIN_IA_COLLECTION = 'ColumbiaUniversityLibraries'
    # For IA, format list must contain 'pdf' because we want to ensure that we only retrieve items
    # that have a PDF version, since EPUB results are subpar right now and will be suppressed in display.
    FORMAT_FILTER = ' AND format:(pdf)'
    DEFAULT_PER_PAGE = 100
    DEFAULT_CRAWLABLE_PER_PAGE = 1000

    before_action :set_ia_feed_id, only: ['show', 'crawlable']

    def index
      # At some point, this may become an OPDS home page with links to various collections.
      # Right now it just redirects to the OPDS feed for all Columbia records.
      redirect_to action: 'show', id: 'all'
      return
    end

    def show
      @page = ia_feed_params.fetch(:page, 1).to_i
      data = Ebooks::IaSearcher.search(
        "collection:#{CGI.escape(@ia_feed_id == 'all' ? MAIN_IA_COLLECTION : @ia_feed_id)}" + FORMAT_FILTER,
        DEFAULT_PER_PAGE,
        @page
      )
      @more_results_available = data['response']['numFound'] > data['response']['start'] + data['response']['docs'].length
      @entries = data['response']['docs'].map { |doc| Ebooks::IaSearcher.doc_to_entry(doc) }
    end

    def crawlable
      # When using scraping api, per_page must be at least 100 because lower per_page value is not supported.
      data = Ebooks::IaSearcher.scraping_api_search(
        "collection:#{CGI.escape(@ia_feed_id == 'all' ? MAIN_IA_COLLECTION : @ia_feed_id)}" + FORMAT_FILTER,
        DEFAULT_CRAWLABLE_PER_PAGE,
        ia_feed_params[:cursor]
      )
      @next_cursor = data['cursor']
      @more_results_available = (data['count'] != data['total']) # count equals total when we're on the last batch
      @entries = data['items'].map { |doc| Ebooks::IaSearcher.doc_to_entry(doc) }
    end

    private

    def set_ia_feed_id
      @ia_feed_id = ia_feed_params[:id]
    end

    def ia_feed_params
      params.permit(:id, :page, :cursor)
    end
  end
end
