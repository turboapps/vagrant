require 'pathname'

module VagrantPlugins
  module Turbo
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :login
      attr_accessor :password
      attr_accessor :inline
      attr_accessor :path
      attr_accessor :install
      attr_reader :images_folders
      attr_reader :upload_path

      def initialize
        super
        @login    = UNSET_VALUE
        @password = UNSET_VALUE
        @inline   = UNSET_VALUE
        @path     = UNSET_VALUE
        @install  = UNSET_VALUE

        # Populated with 'images_folder' method
        @images_folders = []

        # Upload path of Turbo script
        @upload_path = "C:\\tmp\\vagrant-turbo"
      end

      def finalize!
        @login    = nil       if @login    == UNSET_VALUE
        @password = nil       if @password == UNSET_VALUE
        @inline   = nil       if @inline   == UNSET_VALUE
        @path     = nil       if @path     == UNSET_VALUE
        @install  = false     if @install  == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        # Validate types of parameters
        errors << I18n.t("vagrant_turbo.invalid_type", param: "login", type: "String") if \
          login && !login.is_a?(String)
        errors << I18n.t("vagrant_turbo.invalid_type", param: "password", type: "String") if \
          password && !password.is_a?(String)
        errors << I18n.t("vagrant_turbo.invalid_type", param: "inline", type: "String") if \
          inline && !inline.is_a?(String)
        errors << I18n.t("vagrant_turbo.invalid_type", param: "path", type: "String") if \
          path && !path.is_a?(String)
        errors << I18n.t("vagrant_turbo.invalid_type", param: "install", type: "Boolean") if \
          !install.nil? && !!install != install

        # Validate that the parameters are properly set
        errors << I18n.t("vagrant_turbo.login_required") if !login || !password
        errors << I18n.t("vagrant_turbo.path_and_inline_set") if path && inline
        errors << I18n.t("vagrant_turbo.no_path_or_inline") if !path && !inline

        # Validate the existence of a script to upload
        # if path
        #  expanded_path = Pathname.new(path).expand_path(machine.env.root_path)
        #  if !expanded_path.file?
        #    errors << I18n.t("vagrant_turbo.path_invalid", path: expanded_path)
        #  else
        #    data = expanded_path.read(16)
        #    if data && !data.valid_encoding?
        #      errors << I18n.t(
        #        "vagrant_turbo.invalid_encoding",
        #        actual: data.encoding.to_s,
        #        default: Encoding.default_external.to_s,
        #        path: expanded_path.to_s)
        #    end
        #  end
        #end

        # Validate images folders
        #images_folders.each do |local_path, remote_path, opts|
        #  expanded_path = Pathname.new(local_path).expand_path(machine.env.root_path)
        #  if !expanded_path.directory?
        #    errors << I18n.t("vagrant_turbo.images_folder_invalid", path: expanded_path)
        #  end
        #end

        { "turbo provisioner" => errors }
      end

      def images_folder(local_path, remote_path, opts = {})
        @images_folders << [local_path, remote_path, opts]
      end
    end
  end
end
