require 'log4r'
require 'pathname'
require 'tempfile'
require_relative 'client'
require_relative 'installer'

module VagrantPlugins
  module Turbo
    class TurboError < Vagrant::Errors::VagrantError
      error_namespace('vagrant.provisioners.turbo')
    end

    class Provisioner < Vagrant.plugin(2, :provisioner)
      def initialize(machine, config, client = nil, installer = nil)
        super(machine, config)

        @client = client || Client.new(@machine)
        @installer = installer || Installer.new(@machine)
      end

      def configure(root_config)
        config.images_folders.each do |local_path, remote_path, opts|
          root_config.vm.synced_folder(local_path, remote_path, opts)
        end
      end

      def provision
        @logger = Log4r::Logger.new('vagrant::provisioners::turbo')

        @installer.ensure_installed

        @logger.info('Login to the hub')
        @client.login(config.login, config.password)
      end

      private

      def import_images
        config.images_folders.each do |local_path, remote_path, opts|
          exp_local_path = Pathname.new(local_path).expand_path(machine.env.root_path)
          local_images_paths = exp_local_path.entries.select { |e| e.extname.downcase == ".svm" }

          if local_images_paths.empty?
            machine.ui.detail(I18n.t("vagrant_turbo.no_images", path: exp_local_path))
            next
          end

          remote_images_paths = local_images_paths.map { |p| p.expand_path(remote_path).to_s.gsub("/", "\\") }
          remote_images_paths.each do |p|
            machine.ui.detail(I18n.t("vagrant_turbo.import_image", path: p))
            @client.import(p)
          end
        end
      end

      def execute_script
        with_script_file do |path|
          machine.communicate.tap do |comm|
            machine.ui.detail(I18n.t("vagrant_turbo.running", script: config.path || "inline Turbo script"))
            comm.upload(path, config.upload_path)
            comm.sudo("tsh \"#{config.upload_path}\\#{File.basename(path)}\"") do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end

      def with_script_file
        script = nil

        if config.path
          # Read the content of the script
          script = Pathname.new(config.path).expand_path(machine.env.root_path).read
        else
          # The script is just the inline code
          script = config.inline
        end

        # Create temp file for the script
        file = Tempfile.new(["vagrant-turbo", ".tsh"])
        file.binmode

        begin
          file.write(script)
          file.fsync
          file.close
          yield file.path.gsub("/", "\\")
        ensure
          file.close
          file.unlink
        end
      end

      def handle_comm(type, data)
        if [:stderr, :stdout].include?(type)
          data = data.chomp
          options = { :color => type == :stdout ? :green : :red }
          return if data.empty? || !(data =~ /\||\\|\/|\-/).nil?
          machine.ui.detail(data, options)
        end
      end

    end
  end
end
