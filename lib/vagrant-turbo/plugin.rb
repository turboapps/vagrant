require "vagrant"

module VagrantPlugins
  module Turbo
    class Plugin < Vagrant.plugin(2)
      name "turbo"
      description "Provides support for Turbo."

      config(:turbo, :provisioner) do
        require_relative "config"
        Config
      end

      provisioner(:turbo) do
        require_relative "provisioner"
        Provisioner
      end
    end
  end
end
