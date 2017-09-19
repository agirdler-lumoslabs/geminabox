module Geminabox
  module Proxy
    # Handles the orders
    module Server
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def register_routes
          class_eval do
            %w[specs.4.8.gz
               latest_specs.4.8.gz
               prerelease_specs.4.8.gz
            ].each do |index|
              get "/#{@source}/#{index}" do
                content_type 'application/x-gzip'
                serve splice_file(index)
              end
            end

            %w[quick/Marshal.4.8/*.gemspec.rz
               yaml.Z
               Marshal.4.8.Z
            ].each do |deflated_index|
              get "/#{@source}/#{deflated_index}" do
                content_type('application/x-deflate')
                serve copy_file(request.path_info[1..-1])
              end
            end

            %w[yaml
               Marshal.4.8
               specs.4.8
               latest_specs.4.8
               prerelease_specs.4.8
            ].each do |old_index|
              get "/#{@source}/#{old_index}" do
                serve splice_file(old_index)
              end
            end
            get "/#{@source}/api/v1/dependencies" do
              query_gems.any? ? Marshal.dump(gem_list) : 200
            end

            get "/#{@source}/api/v1/dependencies.json" do
              query_gems.any? ? gem_list.to_json : {}
            end

            get "/#{@source}/gems/*.gem" do
              pull_from_repo unless local_file_exists?
              serve
            end
          end
        end
      end
    end

    # Handles the gems
    module Jeweler
      private

      def local_file
        File.expand_path(File.join(Geminabox.data, *request.path_info))
      end

      def serve(file = local_file)
        send_file(file, :type => response['Content-Type'])
      end

      def pull_from_repo
        GemStore.create(incoming_gem)
      end

      def local_file_exists?
        File.exist?(local_file)
      end

      def source
        self.class.source
      end

      def dependency_manager
        DependencyManager[source]
      end

      def gem_list
        dependency_manager.for(*query_gems)
      end

      def query_gems
        params[:gems].to_s.split(',')
      end

      def requested_gem
        request.path_info.split('/').last
      end

      def incoming_gem
        IncomingGem.new(incoming_gem_content, source: source)
      end

      def incoming_gem_content
        StringIO.new Geminabox.http_adapter.get_content(gem_url)
      end

      # This needs to use file join because URI join is basically useless
      def gem_url
        File.join(source_url, 'gems', requested_gem)
      end

      def source_url
        Geminabox.bundler_sources[source]
      end

      def splice_file(file_name)
        Splicer.make(file_name)
      end

      def copy_file(file_name)
        Copier.copy(file_name)
      end
    end

    class Base < Sinatra::Base
      include Jeweler
      include Server

      class << self
        attr_reader :source
      end
    end

    class Gemfury < Base
      @source = :gemfury
      register_routes
    end

    class Rubygems < Base
      @source = :ruby_gems
      register_routes
    end
  end
end
