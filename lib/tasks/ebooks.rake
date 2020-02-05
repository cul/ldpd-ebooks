namespace :ebooks do
  task epub_pdf_report: :environment do
    start_time = Time.now

    # When using scraping api, per_page must be at least 100 because lower per_page value is not supported.
    per_page = 5000
    cursor = nil
    more_results_available = true

    processed_count = 0
    epub_count = 0
    pdf_count = 0
    format_contains_pdf_count = 0
    total = nil
    pdf_format_types = Set.new

    while(more_results_available)
      data = Ebooks::IaSearcher.scraping_api_search(
        "collection:#{CGI.escape(Feeds::IaController::MAIN_IA_COLLECTION)}" + Feeds::IaController::FORMAT_FILTER,
        per_page,
        cursor
      )
      cursor = data['cursor']
      more_results_available = data['total'] > 0
      entries = data['items'].map { |doc| Ebooks::IaSearcher.doc_to_entry(doc) }

      total = data['total'] if total.nil? # first encountered 'total' number is the size of the entire collection

      entries.each do |entry|
        epub_count += 1 if entry.has_epub?
        pdf_count += 1 if entry.has_pdf?
        detected_pdf_format = entry.formats.detect{ |f| f =~ /pdf/i}
        if detected_pdf_format
          format_contains_pdf_count += 1
          pdf_format_types << detected_pdf_format
        end
      end

      processed_count += entries.length
      puts "Processed...#{processed_count} of #{total}"
      break if data['count'] == data['total'] # this is the last batch
    end

    puts "total: #{total}"
    puts "epub: #{epub_count}"
    puts "pdf: #{pdf_count}"
    puts "format contains pdf: #{format_contains_pdf_count}"
    puts "pdf_format_types: " + pdf_format_types.inspect

    puts "\nDone. Finished in: #{Time.now - start_time} seconds."
  end
end
