module VagrantPlugins
  module Turbo
    module Cap
      module TurboInstall
        INSTALLER_URL = "\"http://start.spoon.net/install/?&brand=turbo\""
        INSTALLER_PATH = "\"$env:temp\\installer.exe\""

        def self.turbo_install(machine)
          machine.communicate.sudo("(new-object System.Net.WebClient).DownloadFile(#{INSTALLER_URL}, #{INSTALLER_PATH})")
          # Turbo installer may return non-zero code, when it is not really failed
          machine.communicate.sudo("& #{INSTALLER_PATH} | Out-Null; exit 0")
          machine.communicate.sudo("rm #{INSTALLER_PATH}")
        end
      end
    end
  end
end
