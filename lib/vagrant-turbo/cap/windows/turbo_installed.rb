module VagrantPlugins
  module Turbo
    module Cap
      module Windows
        module TurboInstalled
          def self.turbo_installed(machine)
            machine.communicate.test('turbo version', sudo: true)
          end
        end
      end
    end
  end
end
