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

      guest_capability(:windows, :turbo_installed) do
        require_relative "cap/turbo_installed"
        Cap::TurboInstalled
      end

      guest_capability(:windows, :turbo_install) do
        require_relative "cap/turbo_install"
        Cap::TurboInstall
      end
    end
  end
end
