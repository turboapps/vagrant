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

        @machine.ui.info('Executing command: ' + command)
        run_with_output(command)
      end

      def run(config)
        command = 'turbo run'
        command << " --name=#{config.name}" if config.name
        command << ' --temp' if config.temp
        # HACK - list of images must be passed in quotes. Otherwise Vagrant will split the command.
        command << ' ' << "\"#{config.images.join(',')}\""
        command << " --using=\"#{config.using.join(',')}\"" if config.using.any?
        command << " --isolate=#{config.isolate}" if config.isolate
        command << " --mount \"#{config.script_dir}\"=\"#{config.script_dir}\"" if config.script_dir

        if config.startup_file
          startup_file = config.startup_file
          startup_file = "c:#{startup_file}" if startup_file.start_with?("\\")
          command << " --startup-file=\"#{startup_file}\""
        end

        command << ' --pull' if config.pull
        command << ' --no-stream' if config.no_stream
        command << ' --admin' if config.admin

        command << " --trigger=\"#{config.trigger}\"" if config.trigger
        command << " --vm=#{config.vm}" if config.vm
        command << " --with-root=\"#{with_root}\"" if config.with_root

        command << ' --attach' if config.attach
        command << ' --detach' if config.detach
        command << " --format=#{config.format}" if config.format
        command << ' --diagnostic' if config.diagnostic

        command << flat_with_prefix('--enable=', config.enable) if config.enable
        command << flat_with_prefix('--disable=', config.disable) if config.disable
        command << ' --disable-sync' if config.disable_sync
        command << flat_with_prefix('--env=', config.env) if config.env
        command << " --env-file=\"#{config.env_file}\"" if config.env_file

        command << ' --private' if config.private
        command << ' --public' if config.public
        command << ' --enable-log-stream' if config.enable_log_stream
        command << ' --enable-screencast' if config.enable_screencast
        command << ' --enable-sync' if config.enable_sync

        command << flat_with_prefix('--mount=', config.mount) if config.mount
        command << ' --install' if config.install

        command << " --network=#{config.network}" if config.network
        command << flat_with_prefix('--hosts=', config.hosts) if config.hosts
        command << flat_with_prefix('--link=', config.link) if config.link
        command << flat_with_prefix('--route-add=', config.route_add) if config.route_add
        command << flat_with_prefix('--route-block=', config.route_block) if config.route_block

        @machine.ui.info('Executing command: ' + command)
        run_with_output(command)
      end

      def shell(config)
        with_pretty_print do |output|
          @machine.communicate.execute("tsh \"#{config.path}\"") do |type, data|
            output.append(type, data)
          end
        end
      end

      private

      def flat_with_prefix(prefix, array)
        args_with_prefix = array.map { |value| prefix + value }
        ' ' << args_with_prefix.join(' ')
      end

      def run_with_output(command)
        with_pretty_print do |output|
          @machine.communicate.execute(command) do |type, data|
            output.append(type, data)
          end
        end
      end

      def log_communication(type, data)
        if [:stderr, :stdout].include?(type)
          @logger.info(data)
        end
      end

      def with_pretty_print
        pretty_print = PrettyPrint.new(@machine, @logger)
        yield pretty_print
        pretty_print.flush
      end
    end

    class PrettyPrint
      def initialize(machine, logger)
        @machine = machine
        @logger = logger
        @buffer = []
      end

      def append(type, output)
        unless [:stderr, :stdout].include?(type)
          return
        end

        @logger.info(output)

        # Clear out the newline since we add one
        line = output.chomp
        return if line.empty?

        # Remove progress marquee
        return if '-\|/'.include?(line)

        if line.length > 1
          if @buffer
            prefix = @buffer.join('')
            line = prefix << line
            @buffer.clear
          end
          @machine.ui.info(line)
        else
          @buffer << line
        end
      end

      def flush
        if @buffer
          @machine.ui.info(@buffer.join(''))
        end
      end
    end
  end
end
