# frozen_string_literal: true

class Scholarsphere::Config
  def self.check
    config_files = Dir.glob(File.join(Rails.root, 'config', '*.yml')).map { |f| ConfigFile.new(f) }
    config_files.map(&:validate)
  end

  class ConfigFile
    attr_reader :file

    REQUIREMENTS = {
      'application.yml' => [
        'TMPDIR',
        'ffmpeg_path',
        'service_instance',
        'virtual_host',
        'stats_email',
        'no_reply_email',
        'google_analytics_id',
        'derivatives_path',
        'read_only',
        'EZID_USER',
        'EZID_PASSWORD',
        'EZID_HOST',
        'doi_handle',
        'RECAPTCHA_SITE_KEY',
        'RECAPTCHA_SECRET_KEY',
        'admin_group',
        'network_ingest_directory'
      ]
    }.freeze

    def initialize(file)
      @file = file
    end

    def keys
      YAML.safe_load(File.open(file)).fetch('production', {}).keys
    end

    def validate
      return true if required_keys.empty? || (required_keys - keys).empty?

      raise Error, "Config file #{File.basename(file)} requires #{required_keys} but has #{keys}"
    end

    private

      def required_keys
        REQUIREMENTS.fetch(File.basename(file), [])
      end
  end

  class Error < StandardError; end
end
