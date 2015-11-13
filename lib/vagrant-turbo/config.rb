require 'pathname'

module VagrantPlugins
  module Turbo
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :inline
      attr_accessor :path
      attr_accessor :script_dir
      attr_accessor :powershell_args

      attr_accessor :name
      attr_accessor :images
      attr_accessor :using
      attr_accessor :isolate
      attr_accessor :future
      attr_accessor :startup_file

      def initialize
        super

        @name = UNSET_VALUE
        @images = UNSET_VALUE
        @using = UNSET_VALUE
        @isolate = UNSET_VALUE
        @inline = UNSET_VALUE
        @path = UNSET_VALUE
        @script_dir = UNSET_VALUE
        @powershell_args = UNSET_VALUE
        @future = UNSET_VALUE
        @startup_file = UNSET_VALUE

        @commands = []
      end

      def finalize!
        @login = nil if @login == UNSET_VALUE
        @password = nil if @password == UNSET_VALUE

        @name = nil if @name == UNSET_VALUE
        @images = [] if @images == UNSET_VALUE
        @using = [] if @using == UNSET_VALUE
        @isolate = nil if @isolate == UNSET_VALUE
        @inline = nil if @inline == UNSET_VALUE
        @path = nil if @path == UNSET_VALUE
        @script_dir = 'C:\\tmp\\vagrant-turbo' if @script_dir == UNSET_VALUE
        @powershell_args = nil if @powershell_args == UNSET_VALUE
        @future = nil if @future == UNSET_VALUE
        @startup_file = nil if @startup_file == UNSET_VALUE

        commands.each { |c| c.finalize! }
      end

      def validate(machine)
        errors = _detected_errors

        # Check run parameters
        if isolate
          if !isolate.is_a?(String)
            errors << I18n.t('vagrant_turbo.invalid_type', param: 'isolate', type: 'String')
          elsif !%w(full write-copy merge).include?(isolate.downcase)
            errors << I18n.t('vagrant_turbo.invalid_parameter', param: 'isolate', values: 'full, write-copy, merge')
          end
        end

        if images and !images.is_a?(Array)
          errors << I18n.t('vagrant_turbo.invalid_type', param: 'images', type: 'Array')
        end

        errors << I18n.t('vagrant_turbo.invalid_type', param: 'using', type: 'Array') if using && !using.is_a?(Array)
        errors << I18n.t('vagrant_turbo.invalid_type', param: 'inline', type: 'String') if inline && !inline.is_a?(String)
        errors << I18n.t('vagrant_turbo.invalid_type', param: 'powershell_args', type: 'String') if powershell_args && !powershell_args.is_a?(String)
        errors << I18n.t('vagrant_turbo.invalid_type', param: 'name', type: 'String') if name && !name.is_a?(String)
        errors << I18n.t('vagrant_turbo.invalid_type', param: 'script_dir', type: 'String') if script_dir && !script_dir.is_a?(String)
        errors << I18n.t('vagrant_turbo.invalid_type', param: 'future', type: 'String') if future && !future.is_a?(String)
        errors << I18n.t('vagrant_turbo.invalid_type', param: 'startup_file', type: 'String') if startup_file && !startup_file.is_a?(String)

        if path
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

        errors << I18n.t('vagrant_turbo.path_and_inline_set') if path && inline
        errors << I18n.t('vagrant_turbo.startup_file_with_path_or_inline') if startup_file && (path || inline)

        commands.each { |c| c.validate(machine) }

        {'turbo provisioner' => errors}
      end

      def commands
        @commands
      end

      def login(_name, **_options, &block)
        command = LoginConfig.new
        block.call(command)
        @commands << command
        nil
      end

      def import(_name, **_options, &block)
        command = ImportConfig.new
        block.call(command)
        @commands << command
        nil
      end

      def run?
        images.any?
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
  end
end
