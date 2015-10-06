require "pathname"

module VagrantPlugins
  module Turbo
    class Config < Vagrant.plugin(2, :config)
      attr_accessor :images
      attr_accessor :name
      attr_accessor :inline
      attr_accessor :path
      attr_accessor :install
      attr_accessor :import_images

      def initialize
        super
        @images        = UNSET_VALUE
        @name          = UNSET_VALUE
        @inline        = UNSET_VALUE
        @path          = UNSET_VALUE
        @install       = UNSET_VALUE
        @import_images = UNSET_VALUE
      end

      def finalize!
        @images        = "clean"   if @images        == UNSET_VALUE
        @name          = "default" if @name          == UNSET_VALUE
        @inline        = nil       if @inline        == UNSET_VALUE
        @path          = nil       if @path          == UNSET_VALUE
        @install       = false     if @install       == UNSET_VALUE
        @import_images = nil       if @import_images == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        # Validate that the parameters are properly set
        if path && inline
          errors << I18n.t("vagrant_turbo.path_and_inline_set")
        elsif !path && !inline
          errors << I18n.t("vagrant_turbo.no_path_or_inline")
        end

        # Validate the existence of a script to upload
        if path
          expanded_path = Pathname.new(path).expand_path(machine.env.root_path)
          if !expanded_path.file?
            errors << I18n.t("vagrant_turbo.path_invalid", path: expanded_path)
          else
            data = expanded_path.read(16)
            if data && !data.valid_encoding?
              errors << I18n.t(
                "vagrant_turbo.invalid_encoding",
                actual: data.encoding.to_s,
                default: Encoding.default_external.to_s,
                path: expanded_path.to_s)
            end
          end
        end

        { "turbo provisioner" => errors }
      end
    end
  end
end
