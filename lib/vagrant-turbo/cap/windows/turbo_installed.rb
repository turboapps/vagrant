module VagrantPlugins
  module Turbo
    module Cap
      module Windows
        module TurboInstalled
          def self.turbo_installed(machine)
            command = "if ((& turbo version) -Match 'Version: *') { exit 0 } else { exit 1 }"
            machine.communicate.test(command, sudo: true)
          end
        end
      end
    end
  end
end
