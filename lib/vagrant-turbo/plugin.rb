require 'vagrant'

module VagrantPlugins
  module Turbo
    class Plugin < Vagrant.plugin(2)
      name 'turbo'
      description <<-DESC
      Provides support for Turbo
      DESC

      config(:turbo, :provisioner) do
        require_relative 'config'
        Config
      end

      guest_capability(:windows, :turbo_installed) do
        require_relative 'cap/windows/turbo_installed'
        Cap::Windows::TurboInstalled
      end

      guest_capability(:windows, :turbo_install) do
        require_relative 'cap/windows/turbo_install'
        Cap::Windows::TurboInstall
      end

      guest_capability(:windows, :winrm_get_quota) do
        require_relative 'cap/windows/winrm_get_quota'
        Cap::Windows::WinrmGetQuota
      end

      guest_capability(:windows, :winrm_set_quota) do
        require_relative 'cap/windows/winrm_set_quota'
        Cap::Windows::WinrmSetQuota
      end

      provisioner(:turbo) do
        require_relative 'provisioner'
        Provisioner
      end
    end
  end
end
