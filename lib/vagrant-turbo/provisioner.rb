require "log4r"

module VagrantPlugins
  module Turbo
    class Provisioner < Vagrant.plugin(2, :provisioner)
      def initialize(machine, config)
        @logger = Log4r::Logger.new("vagrant::turbo::provisioner")
      end

      def configure(root_config)
      end

      def provision
      end

      def cleanup
      end
    end
  end
end
