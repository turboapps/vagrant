require "log4r"
require "pathname"

module VagrantPlugins
  module Turbo
    class Provisioner < Vagrant.plugin(2, :provisioner)
      def initialize(machine, config)
        super(machine, config)
        @logger = Log4r::Logger.new("vagrant::turbo::provisioner")
      end

      def configure(root_config)
        config.images_folders.each do |local_path, remote_path, opts|
          root_config.vm.synced_folder local_path, remote_path, opts
        end
      end

      def provision
        install_turbo
        import_images
      end

      def cleanup
      end

      private

      def install_turbo
        return if !config.install

        machine.ui.info(I18n.t("vagrant_turbo.check_install"))
        is_turbo_installed = machine.guest.capability(:turbo_installed)

        if is_turbo_installed
          machine.ui.info(I18n.t("vagrant_turbo.already_installed"))
        else
          machine.ui.info(I18n.t("vagrant_turbo.not_installed"))
          machine.guest.capability(:turbo_install)
        end
      end

      def import_images
        config.images_folders.each do |local_path, remote_path, opts|
          exp_local_path = Pathname.new(local_path).expand_path(machine.env.root_path)
          local_images_paths = exp_local_path.entries.select { |e| e.extname.downcase == ".svm" }

          if local_images_paths.empty?
            machine.ui.info(I18n.t("vagrant_turbo.no_images", path: exp_local_path))
            next
          end

          remote_images_paths = local_images_paths.map { |p| p.expand_path(remote_path).to_s.gsub("/", "\\") }
          remote_images_paths.each do |p|
            machine.ui.info(I18n.t("vagrant_turbo.import_image", path: p))
            machine.guest.capability(:turbo_import, p)
          end
        end
      end

    end
  end
end
