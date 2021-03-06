module VagrantPlugins
  module Turbo
    class Installer
      def initialize(machine)
        @machine = machine
      end

      def ensure_installed
        @machine.ui.info(I18n.t('vagrant_turbo.check_install'))

        unless @machine.guest.capability(:turbo_installed)
          @machine.ui.info(I18n.t('vagrant_turbo.not_installed'))
          @machine.guest.capability(:turbo_install)

          unless @machine.guest.capability(:turbo_installed)
            raise TurboError, :install_failed
          end
        end
      end
    end
  end
end