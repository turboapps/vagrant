module VagrantPlugins
  module Turbo
    class Plugin < Vagrant.plugin(2)
      name "turbo"
      description "Provides support for Turbo."

      provisioner(:turbo) do
        require_relative "provisioner"
        Provisioner
      end
    end
  end
end
