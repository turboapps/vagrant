module VagrantPlugins
  module Turbo
    module Cap
      module Windows
        module WinrmSetQuota
          def self.winrm_set_quota(machine, quota_name, limit)
            machine.communicate.sudo("winrm set winrm/config/winrs '@{#{quota_name}=\"#{limit}\"}'")
          end
        end
      end
    end
  end
end