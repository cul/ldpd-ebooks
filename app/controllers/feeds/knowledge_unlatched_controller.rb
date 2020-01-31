require 'zip'

module Feeds
  class KnowledgeUnlatchedController < ApplicationController

    MARC_SOURCE_DOWNLOAD_URL = 'http://knowledgeunlatched.org/wp-content/uploads/2019/01/Knowledge.Unlatched.KUCombined.20190131.mrc.zip'
    MARC_SOURCE_FILE_NAME_REGEX = /^Knowledge\.Unlatched\.KUCombined\..+\.mrc$/
    KNOWLEDGE_UNLATCHED_CACHE_DIRECTORY = Rails.root.join('tmp', 'knowledge_unlatched_cache')
    MARC_SOURCE_ZIP_CACHE_LOCATION = File.join(KNOWLEDGE_UNLATCHED_CACHE_DIRECTORY, 'latest_marc.zip')
    OPDS_XML_CACHE_LOCATION = File.join(KNOWLEDGE_UNLATCHED_CACHE_DIRECTORY, 'opds_feed.xml')
    # DEFAULT_PER_PAGE = 100
    # DEFAULT_CRAWLABLE_PER_PAGE = 1000

    def index
      # At some point, this may become an OPDS navigable home page.
      # Right now it just redirects to the 'all' action.
      redirect_to action: 'all'
      return
    end

    def all
      unless File.exists?(MARC_SOURCE_ZIP_CACHE_LOCATION)
        FileUtils.mkdir_p(File.dirname(MARC_SOURCE_ZIP_CACHE_LOCATION))
        response = Faraday.new(:url => MARC_SOURCE_DOWNLOAD_URL).get
        File.binwrite(MARC_SOURCE_ZIP_CACHE_LOCATION, response.body)
      end

      @entries = []
      Zip::File.open(MARC_SOURCE_ZIP_CACHE_LOCATION) do |zip_file|
        zip_file.each do |entry|
          if entry.name =~ MARC_SOURCE_FILE_NAME_REGEX
            # Read into memory
            MARC::Reader.new(StringIO.new(entry.get_input_stream.read), external_encoding: 'UTF-8').each do |marc_record|
              puts marc_record['245']['a']
            end
          end
        end
      end

      # @page = ia_feed_params.fetch(:page, 1).to_i
      # data = Ebooks::IaSearcher.search("collection:#{CGI.escape(@ia_feed_id == 'all' ? MAIN_IA_COLLECTION : @ia_feed_id)}", DEFAULT_PER_PAGE, @page)
      # @more_results_available = data['response']['numFound'] > data['response']['start'] + data['response']['docs'].length
      # @entries = data['response']['docs'].map { |doc| Ebooks::IaSearcher.doc_to_entry(doc) }
    end

    # def crawlable
    #   # When using scraping api, per_page must be at least 100 because lower per_page value is not supported.
    #   data = Ebooks::IaSearcher.scraping_api_search("collection:#{CGI.escape(@ia_feed_id == 'all' ? MAIN_IA_COLLECTION : @ia_feed_id)}", DEFAULT_CRAWLABLE_PER_PAGE, ia_feed_params[:cursor])
    #   @next_cursor = data['cursor']
    #   @more_results_available = data['total'] > 0
    #   @entries = data['items'].map { |doc| Ebooks::IaSearcher.doc_to_entry(doc) }
    # end
  end
end
