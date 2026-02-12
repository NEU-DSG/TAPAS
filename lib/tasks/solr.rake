# frozen_string_literal: true

namespace :solr do
  desc "Clear the Solr index and reindex all Projects, Collections, and CoreFiles from the database"
  task reindex: :environment do
    total_projects    = Project.count
    total_collections = Collection.count
    total_core_files  = CoreFile.count
    total             = total_projects + total_collections + total_core_files

    puts "This will clear the Solr index and reindex #{total} records:"
    puts "  Projects:    #{total_projects}"
    puts "  Collections: #{total_collections}"
    puts "  CoreFiles:   #{total_core_files}"
    puts "\nPress Ctrl+C to cancel, or Enter to continue..."
    STDIN.gets

    connection = SolrHelpers::SOLR_CORE_CONNECTION
    errors = []

    puts "\nClearing existing Solr index..."
    connection.delete_by_query("*:*")
    connection.commit
    puts "Index cleared."

    {
      "Projects"    => Project,
      "Collections" => Collection,
      "CoreFiles"   => CoreFile
    }.each do |label, model|
      puts "\nIndexing #{label}..."

      model.find_each do |record|
        begin
          connection.add(record.to_solr)
          print "."
        rescue => e
          errors << "#{model} #{record.id}: #{e.message}"
          print "x"
        end
      end

      connection.commit
      puts " done."
    end

    puts "\nOptimizing index and rebuilding spellcheck indexes..."
    connection.optimize
    puts "Optimize complete."

    if errors.any?
      puts "\nCompleted with #{errors.count} error(s):"
      errors.each { |e| puts "  x #{e}" }
      exit 1
    else
      puts "\nReindex complete. #{total} records indexed."
    end
  end

  desc "Optimize the Solr index to trigger spellcheck index rebuild"
  task optimize: :environment do
    puts "Optimizing Solr index..."
    SolrHelpers::SOLR_CORE_CONNECTION.optimize
    puts "Done."
  end
end
