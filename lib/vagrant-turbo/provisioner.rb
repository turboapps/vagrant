require 'log4r'
require 'pathname'
require 'tempfile'
require_relative 'client'
require_relative 'installer'
require_relative 'config'

module VagrantPlugins
  module Turbo
    class TurboError < Vagrant::Errors::VagrantError
      error_namespace('vagrant.provisioners.turbo')
    end

    class Provisioner < Vagrant.plugin(2, :provisioner)
      def initialize(machine, config, client = nil, installer = nil)
        super(machine, config)

        @client = client || Client.new(machine)
        @installer = installer || Installer.new(machine)
      end

      def provision
        @logger = Log4r::Logger.new('vagrant::provisioners::turbo')

        @logger.info('Ensure turbo installed')
        @installer.ensure_installed

        config.commands.each do |command|
          if command.is_a?(ImportConfig)
            import(command)
            next
          end

          if command.is_a?(LoginConfig)
            login(command)
            next
          end

          if command.is_a?(RunConfig)
            run(command)
            next
          end

          if command.is_a?(TurboShellConfig)
            shell(command)
          end
        end
      end

      private

      def login (login_config)
        @logger.info('Login to the hub')
        @client.login(login_config)
      end

      def run(run_config)
        run_config.startup_file = build_startup_file(run_config)
        @client.run(run_config)
      end

      def import(import_config)
        import_config.path = expand_guest_path(import_config.path)
        @client.import(import_config)
      end

      def shell(shell_config)
        with_script_file(shell_config) do |path|
          machine.communicate.tap do |comm|
            machine.ui.info(I18n.t('vagrant_turbo.running', script: shell_config.path || 'inline Turbo script'))
            comm.upload(path, shell_config.script_dir)
            shell_config.path = File.join(shell_config.script_dir, File.basename(path))
            @client.shell(shell_config)
          end
        end
      end

      def build_startup_file(config)
        machine.communicate.tap do |comm|
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
            return upload_startup_file(comm, dir_to_use, config.inline)
          end
        end
      end

      def cleanup
      end

      def upload_startup_file(comm, guest_dir, *lines)
        file_name = 'turbo-launch.bat'
        startup_file = File.join(guest_dir, file_name)

        @logger.info("Creating startup file #{startup_file}")
        temp_file = Tempfile.new(file_name)
        begin
          temp_file.puts(lines)
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
          destination.to_s.gsub('/', "\\")
        end
      end

      def with_script_file(config)
        script = if config.path
                   # Read the content of the script
                   Pathname.new(config.path).expand_path(machine.env.root_path).read
                 else
                   # The script is just the inline code
                   config.inline
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
          options = {:color => type == :stdout ? :green : :red}
          return if data.empty? || !(data =~ /\||\\|\/|\-/).nil?
          machine.ui.info(data, options)
        end
      end
    end
  end
end
