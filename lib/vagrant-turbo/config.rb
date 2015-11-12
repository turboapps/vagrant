require 'pathname'

module VagrantPlugins
  module Turbo
    class Config < Vagrant.plugin('2', :config)
      attr_accessor :login
      attr_accessor :password

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

      attr_reader :images_folders
      attr_reader :upload_path

      def initialize
        super
        @login = UNSET_VALUE
        @password = UNSET_VALUE

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

        # Populated with 'images_folder' method
        @images_folders = []

        # Upload path of Turbo script
        @upload_path = "C:\\tmp\\vagrant-turbo"
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
      end

      def validate(machine)
        errors = _detected_errors

        # Check login and password
        if login || password
          if login && !login.is_a?(String)
            I18n.t('vagrant_turbo.invalid_type', param: 'login', type: 'String')
          end

          if password && password.is_a?(String)
            I18n.t('vagrant_turbo.invalid_type', param: 'password', type: 'String')
          end

          errors << I18n.t('vagrant_turbo.login_required') if !login || !password
        end

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
        elsif images.empty?
          errors << I18n.t('vagrant_turbo.no_images_to_run')
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

        # Validate images folders
        images_folders.each do |local_path, remote_path, opts|
          expanded_path = Pathname.new(local_path).expand_path(machine.env.root_path)
          unless expanded_path.directory?
            errors << I18n.t('vagrant_turbo.images_folder_invalid', path: expanded_path)
          end
        end

        {'turbo provisioner' => errors}
      end

      def images_folder(local_path, remote_path, opts = {})
        @images_folders << [local_path, remote_path, opts]
      end
    end
  end
end
