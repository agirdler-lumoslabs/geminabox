
module Geminabox
  module Proxy
    def self.proxy_path(file)
      File.join File.dirname(__FILE__), 'proxy', file
    end

    autoload :FileHandler,  proxy_path('file_handler')
    autoload :Splicer,      proxy_path('splicer')
    autoload :Copier,       proxy_path('copier')
    autoload :Base,         proxy_path('base')
    autoload :Gemfury,      proxy_path('base')
    autoload :Rubygems,     proxy_path('base')
  end
end
