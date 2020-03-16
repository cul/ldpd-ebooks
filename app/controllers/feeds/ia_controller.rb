module Feeds
  class IaController < ApplicationController

    MAIN_IA_COLLECTION = 'ColumbiaUniversityLibraries'
    # Note 1: For IA, format list must contain 'pdf' because we want to ensure that we only retrieve items
    # that have a PDF version, since EPUB results are subpar right now and will be suppressed in display.
    # Note 2: We never want to pull in "Collection Header" format items, since they represent collections
    # of things rather than individual items.
    FORMAT_FILTER = ' AND format:pdf AND -format:(Collection Header)'
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
      data = @ia_feed_id == 'mock' ? mock_ia_data : Ebooks::IaSearcher.search(
        "collection:#{CGI.escape(@ia_feed_id == 'all' ? MAIN_IA_COLLECTION : @ia_feed_id)}" + FORMAT_FILTER,
        DEFAULT_PER_PAGE,
        @page
      )
      @more_results_available = data['response']['numFound'] > data['response']['start'] + data['response']['docs'].length
      @entries = data['response']['docs'].map { |doc| Ebooks::IaSearcher.doc_to_entry(doc) }
    end

    def crawlable
      # When using scraping api, per_page must be at least 100 because lower per_page value is not supported.
      data = @ia_feed_id == 'mock' ? mock_crawlable_ia_data : Ebooks::IaSearcher.scraping_api_search(
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

    def mock_ia_data
      # From: https://archive.org/advancedsearch.php?q=collection%3AColumbiaUniversityLibraries&fl%5B%5D=avg_rating&fl%5B%5D=backup_location&fl%5B%5D=btih&fl%5B%5D=call_number&fl%5B%5D=collection&fl%5B%5D=contributor&fl%5B%5D=coverage&fl%5B%5D=creator&fl%5B%5D=date&fl%5B%5D=description&fl%5B%5D=downloads&fl%5B%5D=external-identifier&fl%5B%5D=foldoutcount&fl%5B%5D=format&fl%5B%5D=genre&fl%5B%5D=headerImage&fl%5B%5D=identifier&fl%5B%5D=imagecount&fl%5B%5D=indexflag&fl%5B%5D=item_size&fl%5B%5D=language&fl%5B%5D=licenseurl&fl%5B%5D=mediatype&fl%5B%5D=members&fl%5B%5D=month&fl%5B%5D=name&fl%5B%5D=noindex&fl%5B%5D=num_reviews&fl%5B%5D=oai_updatedate&fl%5B%5D=publicdate&fl%5B%5D=publisher&fl%5B%5D=related-external-id&fl%5B%5D=reviewdate&fl%5B%5D=rights&fl%5B%5D=scanningcentre&fl%5B%5D=source&fl%5B%5D=stripped_tags&fl%5B%5D=subject&fl%5B%5D=title&fl%5B%5D=type&fl%5B%5D=volume&fl%5B%5D=week&fl%5B%5D=year&sort%5B%5D=identifier+asc&sort%5B%5D=&sort%5B%5D=&rows=100&page=1&output=json
      @mock_ia_data ||= JSON.parse(IO.read(Rails.root.join('spec', 'fixtures', 'ia', 'sample_100_record_ia_response.json')))
    end

    def mock_crawlable_ia_data
      # From: https://archive.org/services/search/v1/scrape?q=collection%3AColumbiaUniversityLibraries&fields=avg_rating,backup_location,btih,call_number,collection,contributor,coverage,creator,date,description,downloads,external-identifier,foldoutcount,format,genre,headerImage,identifier,imagecount,indexflag,item_size,language,licenseurl,mediatype,members,month,name,noindex,num_reviews,oai_updatedate,publicdate,publisher,related-external-id,reviewdate,rights,scanningcentre,source,stripped_tags,subject,title,type,volume,week,year&sort%5B%5D=identifier+asc&sort%5B%5D=&sort%5B%5D=&count=100
      @mock_ia_data ||= JSON.parse(IO.read(Rails.root.join('spec', 'fixtures', 'ia', 'sample_100_record_crawlable_ia_response.json')))
    end
  end
end
