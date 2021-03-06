module VagrantPlugins
  module Turbo
    module Cap
      module Windows
        module TurboInstall
          INSTALLER_URL = "\"http://start.spoon.net/install/?&brand=turbo\""
          INSTALLER_PATH = "\"$env:temp\\installer.exe\""

          def self.turbo_install(machine)
            # TODO: use Vagrant utility to download files
            machine.communicate.sudo("(new-object System.Net.WebClient).DownloadFile(#{INSTALLER_URL}, #{INSTALLER_PATH})")
            # Turbo installer may return non-zero code, when it is not really failed
            machine.communicate.sudo("& #{INSTALLER_PATH} | Out-Null; exit 0")
          end
        end
      end
    end
  end
end
