module VagrantPlugins
  module Turbo
    class Client
      def initialize(machine)
        @machine = machine
      end

      def login(username, password)
        @machine.ui.detail(I18n.t('vagrant_turbo.login', login: username))
        run_with_output("turbo login #{username} #{password} --format=json")
      end

      def import(svm_path)
        run_with_output("turbo import svm \"#{svm_path}\" --overwrite")
      end

      def run_file(filepath)
        run_with_output("turbo run clean --attach -- #{filepath}")
      end

      private

      def run_with_output(command)
        @machine.communicate.sudo(command) do |type, data|
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
