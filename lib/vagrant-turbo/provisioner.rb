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

        @logger.info('Ensure turbo installed')
        @installer.ensure_installed

        if config.login && config.password
          @logger.info('Login to the hub')
          @client.login(config.login, config.password)
        end

        setup_startup_file!

        @client.run(config)
      end

      private

      def setup_startup_file!
        if config.path || config.inline
          @machine.communicate.tap do |comm|
            config.startup_file = build_startup_file(comm, config)
          end
        end
      end

      def build_startup_file(comm, config)
        dir_to_use = expand_guest_path(config.script_dir)

        # Make sure the remote path exists
        comm.execute("mkdir '#{dir_to_use}'")

        if config.path
          file_to_upload = File.expand_path(config.path)

          @logger.info("Uploading #{file_to_upload} to #{dir_to_use}")
          comm.upload(file_to_upload, dir_to_use)

          if File.extname(file_to_upload).casecmp('.ps1') == 0
            # Hack create bat script to launch Powershell
            launch_command = 'powershell'
            if config.powershell_args
              launch_command << ' -ExecutionPolicy Bypass' if config.powershell_args !~ /[-\/]ExecutionPolicy/i
              launch_command << ' -OutputFormat Text' if config.powershell_args !~ /[-\/]OutputFormat/i
              launch_command << ' ' << config.powershell_args
            else
              launch_command << ' -ExecutionPolicy Bypass -OutputFormat Text'
            end
            launch_command << " -File \"#{File.join(dir_to_use, File.basename(file_to_upload))}\""

            return upload_startup_file(comm, dir_to_use, launch_command)
          else
            return File.join(dir_to_use, File.basename(config.path))
          end
        else
          upload_startup_file(comm, dir_to_use, config.inline)
        end
      end

      def upload_startup_file(comm, guest_dir, *content)
        file_name = 'turbo-launch.bat'
        startup_file = File.join(guest_dir, file_name)

        @logger.info("Creating startup file #{startup_file}")
        temp_file = Tempfile.new(file_name)
        begin
          temp_file.puts(content)
          temp_file.close
          comm.upload(File.expand_path(temp_file.path), startup_file)
        ensure
          temp_file.close
          temp_file.unlink
        end

        startup_file
      end

      # Expand the guest path if the guest has the capability
      def expand_guest_path(destination)
        if machine.guest.capability?(:shell_expand_guest_path)
          machine.guest.capability(:shell_expand_guest_path, destination)
        else
          destination
        end
      end

      def import_images
        config.images_folders.each do |local_path, remote_path, opts|
          exp_local_path = Pathname.new(local_path).expand_path(machine.env.root_path)
          local_images_paths = exp_local_path.entries.select { |e| e.extname.downcase == '.svm' }

          if local_images_paths.empty?
            machine.ui.detail(I18n.t('vagrant_turbo.no_images', path: exp_local_path))
            next
          end

          remote_images_paths = local_images_paths.map { |p| p.expand_path(remote_path).to_s.gsub('/', "\\") }
          remote_images_paths.each do |p|
            machine.ui.detail(I18n.t('vagrant_turbo.import_image', path: p))
            @client.import(p)
          end
        end
      end

      def execute_script
        with_script_file do |path|
          machine.communicate.tap do |comm|
            machine.ui.detail(I18n.t('vagrant_turbo.running', script: config.path || 'inline Turbo script'))
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
        file = Tempfile.new(%w(vagrant-turbo .tsh))
        file.binmode

        begin
          file.write(script)
          file.fsync
          file.close
          yield file.path.gsub('/', "\\")
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
