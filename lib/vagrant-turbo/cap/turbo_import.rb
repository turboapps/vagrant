module VagrantPlugins
  module Turbo
    module Cap
      module TurboImport
        def self.turbo_import(machine, path)
          machine.communicate.sudo("turbo import svm \"#{path}\"")
        end
      end
    end
  end
end
