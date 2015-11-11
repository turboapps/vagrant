require 'vagrant-turbo/plugin'

module VagrantPlugins
  module Turbo
    LOCALES_PATH = 'locales/en.yml'

    def self.root
      File.expand_path '../..', __FILE__
    end

    def self.setup_locales
      I18n.load_path << File.expand_path(LOCALES_PATH, root)
      I18n.reload!
    end

    setup_locales
  end
end
