# frozen_string_literal: true

require 'fcrepo_wrapper'
require 'fcrepo_wrapper/rake_task'
require 'solr_wrapper'
require 'active_fedora/cleaner'

namespace :solr do
  desc 'Starts a configured solr instance for local development and testing'
  task start: :environment do
    solr.extract_and_configure
    solr.start
    solr.create(name: 'hydra-development', dir: solr_config)
    solr.create(name: 'hydra-test', dir: solr_config)
  end

  def solr_config
    File.join(Rails.root, 'solr', 'config')
  end

  def solr
    @solr ||= SolrWrapper.default_instance(
      port: '8983',
      instance_dir: 'tmp/solr',
      download_dir: 'tmp'
    )
  end
end

namespace :filestore do
  desc 'Starts up the server for the remote file store'
  task start: :environment do
    system(
      "cd #{Rails.root.join('public')} && "\
      "python -m SimpleHTTPServer #{URI(ENV['REPOSITORY_FILESTORE_HOST']).port} &> "\
      '../log/filestore.log &'
    )
  end

  desc 'Stops all instances of the remote file store'
  task stop: :environment do
    system("ps -ax | grep SimpleHTTPServer | awk '{print $1}' | xargs kill -s KILL &> /dev/null")
  end
end

namespace :dev do
  desc "Cleans out everything. Everything. Don't try this at home."
  task clean: :environment do
    ActiveFedora::Cleaner.clean!
    cleanout_redis
    clear_directories
    Rake::Task['db:reset'].invoke
    Rake::Task['sufia:default_admin_set:create'].invoke
    Rake::Task['curation_concerns:workflow:load'].invoke
  end

  def clear_directories
    FileUtils.rm_rf(Sufia.config.derivatives_path)
    FileUtils.mkdir_p(Sufia.config.derivatives_path)
    FileUtils.rm_rf(Sufia.config.upload_path.call)
    FileUtils.mkdir_p(Sufia.config.upload_path.call)
    FileUtils.rm_rf(ENV['REPOSITORY_FILESTORE'])
    FileUtils.mkdir_p(ENV['REPOSITORY_FILESTORE'])
    FileUtils.mkdir_p(ScholarSphere::Application.config.network_ingest_directory)
  end

  def cleanout_redis
    Redis.current.keys.map { |key| Redis.current.del(key) }
  rescue StandardError => e
    Logger.new(STDOUT).warn "WARNING -- Redis might be down: #{e}"
  end
end

namespace :coveralls do
  desc 'Report line count statistics from Coveralls'
  task line_report: :environment do
    report = Rails.root.join('coverage/.resultset.json')
    unless report.exist?
      raise ArgumentError, 'No coveralls report found. Run `bundle exec coveralls report` to generate'
    end

    results = JSON.parse(File.read(report))

    CSV.open(Rails.root.join('coverage/line_report.csv'), 'w') do |csv|
      csv << ['Test', 'Max', 'Average']
      results['spec']['coverage'].each do |key, values|
        values.compact!
        csv << [Pathname.new(key).basename, values.max, (values.sum / values.length)]
      end
    end
  end
end
