require "log4r"

module VagrantPlugins
  module Turbo
    class Provisioner < Vagrant.plugin(2, :provisioner)
      def initialize(machine, config)
        super(machine, config)
        @logger = Log4r::Logger.new("vagrant::turbo::provisioner")
      end

      def configure(root_config)
      end

      def provision
        install_turbo
      end

      def cleanup
      end

      private

      def install_turbo
        return if !@config.install

        @machine.ui.info(I18n.t("vagrant_turbo.check_install"))
        is_turbo_installed = @machine.guest.capability(:turbo_installed)

        if is_turbo_installed
          @machine.ui.info(I18n.t("vagrant_turbo.already_installed"))
        else
          @machine.ui.info(I18n.t("vagrant_turbo.not_installed"))
          @machine.guest.capability(:turbo_install)
        end
      end

    end
  end
end
