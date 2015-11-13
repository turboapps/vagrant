module VagrantPlugins
  module Turbo
    class Client
      def initialize(machine)
        @machine = machine
        @logger = Log4r::Logger.new('vagrant::provisioners::turbo::client')
      end

      def login(config)
        @machine.ui.info(I18n.t('vagrant_turbo.login', username: config.username))
        run_with_output("turbo login #{config.username} #{config.password} --format=json")
      end

      def import(config)
        @machine.ui.info(I18n.t('vagrant_turbo.import_image', path: config.path))

        command = "turbo import #{config.type}"
        command << " --name=#{config.name}" if config.name
        command << ' --overwrite' if config.overwrite
        command << ' ' << config.path
        run_with_output(command)
      end

      def run(config)
        command = 'turbo run'

        # HACK - list of images must be passed in quotes. Otherwise Vagrant will split command into two.
        command << ' ' << "\"#{config.images.join(',')}\""
        command << " --using=\"#{config.using.join(',')}\"" if config.using.any?
        command << " --name=#{config.name}" if config.name
        command << " --mount \"#{config.script_dir}\"=\"#{config.script_dir}\"" if config.script_dir

        # TODO check if detach or enable sync are passed in future
        command << ' --attach' if config.future !~ /attach/i
        command << ' --disable-sync' if config.future !~ /disable-sync/i
        command << ' ' << config.future if config.future

        startup_file = config.startup_file
        startup_file = "c:#{startup_file}" if startup_file.start_with?("\\")
        command << " --startup-file=\"#{startup_file}\""

        @logger.debug('Executing command: ' + command)
        @machine.ui.info('Executing command: ' + command)

        run_with_output(command)
      end

      def shell(config)
        @machine.communicate.execute("tsh \"#{config.path}\"") do |type, data|
          handle_comm(type, data)
        end
      end

      private

      def run_with_output(command)
        @machine.communicate.execute(command) do |type, data|
          handle_comm(type, data)
        end
      end

      # This handles outputting the communication data back to the UI
      def handle_comm(type, data)
        if [:stderr, :stdout].include?(type)
          # Clear out the newline since we add one
          data = data.chomp
          return if data.empty?

          options = {}
          #options[:color] = color if !config.keep_color

          @machine.ui.info(data.chomp, options)
        end
      end
    end
  end
end
