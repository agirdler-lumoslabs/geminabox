require 'json'
require 'uri'

module Geminabox
  class DependencyManager
    attr_accessor :bundler_url

    def self.[](source)
      new(Geminabox.bundler_sources[source])
    end

    def initialize(bundler_url)
      self.bundler_url = bundler_url
    end

    def for(*gems)
      content = Geminabox.http_adapter.get_content(url_for_gems(*gems))
      Marshal.load(content)
    rescue => e
      return [] if Geminabox.allow_remote_failure
      raise e
    end

    private

    def url_for_gems(*gems)
      [
        remote_uri,
        '?gems=',
        gems.map(&:to_s).join(',')
      ].join
    end

    def remote_uri
      File.join(bundler_url, 'api/v1/dependencies')
    end
  end
end
