require 'pathname'

module VagrantPlugins
  module Turbo
    class ConfigUtils
      def self.validate_path(path, machine, errors)
        errors << I18n.t('vagrant_turbo.invalid_type', param: 'path', type: 'String') unless path.is_a?(String)
        expanded_path = Pathname.new(path).expand_path(machine.env.root_path)
        if expanded_path.file?
          data = expanded_path.read(16)
          if data && !data.valid_encoding?
            errors << I18n.t(
                'vagrant_turbo.invalid_encoding',
                actual: data.encoding.to_s,
                default: Encoding.default_external.to_s,
                path: expanded_path.to_s)
          end
        else
          errors << I18n.t('vagrant_turbo.path_invalid', path: expanded_path)
        end
      end
    end

    class Config < Vagrant.plugin('2', :config)
      def initialize
        super

        @__command_names = []
        @__commands = {}
      end

      def finalize!
        commands.each { |c| c.finalize! }
      end

      def validate(machine)
        errors = _detected_errors

        commands.each { |c| c.validate(machine) }

        {'turbo provisioner' => errors}
      end

      def commands
        @__command_names.map { |name| @__commands[name] }
      end

      def login(name, **options, &block)
        _add_command(name, LoginConfig, **options, &block)
      end

      def import(name, **options, &block)
        _add_command(name, ImportConfig, **options, &block)
      end

      def run(name, **options, &block)
        _add_command(name, RunConfig, **options, &block)
      end

      def shell(name, **options, &block)
        _add_command(name, TurboShellConfig, **options, &block)
      end

      private

      def _add_command(name, type, **_options, &block)
        name_to_use = name || "__default_#{type.name}"
        command = @__commands[name_to_use]
        unless command
          command = type.new
          @__commands[name_to_use] = command
          @__command_names << name_to_use
        end

        block.call(command) if block_given?
        nil
      end
    end

    class LoginConfig < Vagrant.plugin('2', :config)
      attr_accessor :username
      attr_accessor :password

      def initialize
        @username = UNSET_VALUE
        @password = UNSET_VALUE
      end

      def validate(_machine)
        errors = _detected_errors

        # Check login and password
        if username && !username.is_a?(String)
          I18n.t('vagrant_turbo.invalid_type', param: 'username', type: 'String')
        end

        if password && password.is_a?(String)
          I18n.t('vagrant_turbo.invalid_type', param: 'password', type: 'String')
        end

        errors << I18n.t('vagrant_turbo.login_required') if !username || !password
      end

      def finalize!
      end
    end

    class ImportConfig < Vagrant.plugin('2', :config)
      attr_accessor :name
      attr_accessor :path
      attr_accessor :type
      attr_accessor :overwrite

      def initialize
        super
        @path = UNSET_VALUE
        @name = UNSET_VALUE
        @type = UNSET_VALUE
        @overwrite = UNSET_VALUE
      end

      def validate(_machine)
      end

      def finalize!
        @name = nil if @name == UNSET_VALUE
        @type = 'SVM' if @type == UNSET_VALUE
        @overwrite = true if @overwrite == UNSET_VALUE
      end
    end

    class RunConfig < Vagrant.plugin('2', :config)
      attr_accessor :inline
      attr_accessor :path
      attr_accessor :script_dir
      attr_accessor :powershell_args

      attr_accessor :name
      attr_accessor :temp
      attr_accessor :images
      attr_accessor :using
      attr_accessor :isolate
      attr_accessor :startup_file
      attr_accessor :pull
      attr_accessor :no_stream
      attr_accessor :admin

      attr_accessor :trigger
      attr_accessor :vm
      attr_accessor :with_root

      attr_accessor :attach
      attr_accessor :detach
      attr_accessor :format
      attr_accessor :diagnostic

      attr_accessor :enable
      attr_accessor :disable
      attr_accessor :disable_sync
      attr_accessor :env
      attr_accessor :env_file

      attr_accessor :private
      attr_accessor :public
      attr_accessor :enable_log_stream
      attr_accessor :enable_screencast
      attr_accessor :enable_sync

      attr_accessor :mount
      attr_accessor :install

      attr_accessor :network
      attr_accessor :hosts
      attr_accessor :link
      attr_accessor :route_add
      attr_accessor :route_block

      def initialize
        @inline = UNSET_VALUE
        @path = UNSET_VALUE
        @script_dir = UNSET_VALUE
        @powershell_args = UNSET_VALUE

        @name = UNSET_VALUE
        @temp = UNSET_VALUE
        @images = UNSET_VALUE
        @using = UNSET_VALUE
        @isolate = UNSET_VALUE
        @startup_file = UNSET_VALUE
        @pull = UNSET_VALUE
        @no_stream = UNSET_VALUE
        @admin = UNSET_VALUE

        @trigger = UNSET_VALUE
        @vm = UNSET_VALUE
        @with_root = UNSET_VALUE

        @attach = UNSET_VALUE
        @detach = UNSET_VALUE
        @format = UNSET_VALUE
        @diagnostic = UNSET_VALUE

        @enable = UNSET_VALUE
        @disable = UNSET_VALUE
        @env = UNSET_VALUE
        @env_file = UNSET_VALUE

        @private = UNSET_VALUE
        @public = UNSET_VALUE
        @enable_log_stream = UNSET_VALUE
        @enable_sync = UNSET_VALUE
        @disable_sync = UNSET_VALUE

        @mount = UNSET_VALUE
        @install = UNSET_VALUE

        @network = UNSET_VALUE
        @hosts = UNSET_VALUE
        @link = UNSET_VALUE
        @route_add = UNSET_VALUE
        @route_block = UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        # Check script parameters
        errors << require_string('inline', inline)
        ConfigUtils.validate_path(path, machine, errors) if path
        errors << I18n.t('vagrant_turbo.path_and_inline_set') if path && inline
        errors << require_string('powershell_args', powershell_args)
        errors << require_string('script_dir', script_dir)

        # Check run parameters
        errors << require_string('name', name)
        errors << require_bool('temp', temp)
        errors << require_array('images', images)
        errors << require_array('using', using)
        if isolate
          if !isolate.is_a?(String)
            errors << I18n.t('vagrant_turbo.invalid_type', param: 'isolate', type: 'String')
          elsif !%w(full write-copy merge).include?(isolate.downcase)
            errors << I18n.t('vagrant_turbo.invalid_parameter', param: 'isolate', values: 'full, write-copy, merge')
          end
        end
        errors << require_string('startup_file', startup_file)
        errors << require_bool('no_stream', no_stream)
        errors << require_bool('admin', admin)
        errors << require_bool('pull', pull)

        errors << require_string('trigger', trigger)
        errors << require_string('vm', vm)
        errors << require_string('with_root', with_root)

        errors << require_bool('detach', detach)
        errors << require_bool('attach', attach)
        errors << require_string('format', format)
        errors << require_bool('diagnostic', diagnostic)

        errors << require_array('enable', enable)
        errors << require_array('disable', disable)
        errors << require_array('env', env)
        errors << require_string('env_file', env_file)

        errors << require_bool('private', private)
        errors << require_bool('public', public)
        errors << require_bool('enable_log_stream', enable_log_stream)
        errors << require_bool('enable_screencast', enable_screencast)
        errors << require_bool('enable_sync', enable_sync)
        errors << require_bool('disable_sync', disable_sync)

        errors << require_array('mount', mount)
        errors << require_bool('install', install)

        errors << require_string('network', network)
        errors << require_array('hosts', hosts)
        errors << require_array('link', link)
        errors << require_array('route_add', route_add)
        errors << require_array('route_block', route_block)

        errors << I18n.t('vagrant_turbo.startup_file_with_path_or_inline') if startup_file && (path || inline)
      end

      def finalize!
        @inline = nil if @inline == UNSET_VALUE
        @path = nil if @path == UNSET_VALUE
        @script_dir = 'C:\\tmp\\vagrant-turbo' if @script_dir == UNSET_VALUE
        @powershell_args = nil if @powershell_args == UNSET_VALUE

        @name = nil if @name == UNSET_VALUE
        @temp = false if @temp == UNSET_VALUE
        @images = [] if @images == UNSET_VALUE
        @using = [] if @using == UNSET_VALUE
        @isolate = nil if @isolate == UNSET_VALUE
        @startup_file = nil if @startup_file == UNSET_VALUE
        @pull = false if @pull == UNSET_VALUE
        @no_stream = false if @no_stream == UNSET_VALUE
        @admin = false if @admin == UNSET_VALUE

        @trigger = nil if @trigger == UNSET_VALUE
        @vm = nil if @vm == UNSET_VALUE
        @with_root = nil if @with_root == UNSET_VALUE

        @detach = false if @detach == UNSET_VALUE
        @attach = false if @attach == UNSET_VALUE
        @format = nil if @format == UNSET_VALUE
        @diagnostic = false if @diagnostic == UNSET_VALUE

        @enable = [] if @enable == UNSET_VALUE
        @disable = [] if @disable == UNSET_VALUE
        @env = [] if @env == UNSET_VALUE
        @env_file = nil if @env_file == UNSET_VALUE

        @private = false if @private == UNSET_VALUE
        @public = false if @public == UNSET_VALUE
        @enable_log_stream = false if @enable_log_stream == UNSET_VALUE
        @enable_screencast = false if @enable_screencast == UNSET_VALUE
        @enable_sync = false if @enable_sync == UNSET_VALUE
        @disable_sync = false if @disable_sync == UNSET_VALUE

        @mount = [] if @mount == UNSET_VALUE
        @install = false if @install == UNSET_VALUE

        @network = nil if @network == UNSET_VALUE
        @hosts = [] if @hosts == UNSET_VALUE
        @link = [] if @link == UNSET_VALUE
        @route_add = [] if @route_add == UNSET_VALUE
        @route_block = [] if @route_block == UNSET_VALUE
      end

      private

      def require_bool(param_name, value)
        I18n.t('vagrant_turbo.invalid_type', param: param_name, type: 'Boolean') unless !!value == value
      end

      def require_string(param_name, value)
        errors << I18n.t('vagrant_turbo.invalid_type', param: param_name, type: 'String') if value && !value.is_a?(String)
      end

      def require_array(param_name, value)
        errors << I18n.t('vagrant_turbo.invalid_type', param: param_name, type: 'Array') if value && !value.is_a?(Array)
      end
    end

    class TurboShellConfig < Vagrant.plugin('2', :config)
      attr_accessor :inline
      attr_accessor :path
      attr_accessor :script_dir

      def initialize
        @inline = UNSET_VALUE
        @path = UNSET_VALUE
        @script_dir = UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors
        errors << I18n.t('vagrant_turbo.invalid_type', param: 'inline', type: 'String') if inline && !inline.is_a?(String)
        ConfigUtils.validate_path(path, machine, errors) if path

        errors << I18n.t('vagrant_turbo.path_and_inline_set') if path && inline
        errors << I18n.t('vagrant_turbo.path_and_inline_set') if path && inline
      end

      def finalize!
        @script_dir = 'C:\\tmp\\vagrant-turbo' if @script_dir == UNSET_VALUE
        @path = nil if @path == UNSET_VALUE
        @inline = nil if @inline == UNSET_VALUE
      end
    end
  end
end
