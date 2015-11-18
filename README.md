# Vagrant Turbo Provisioner
Enable Vagrant to manage Turbo containers.

The plugin supports a subset of features available in Turbo Console and Turbo Shell which are reasonable in provisioning a virtual machine:
* Install the latest version of the Turbo Plugin
* Login to the Turbo Hub
* Run a Turbo container
* Import an image from the local file system on guest machine
* Build an image using Turbo Shell
* Manage quota for remote shells

Remaining sections will explain how to install vagrant-turbo plugin on a host machine, configure the provisioner and setup development environment.

## Installation
* Install [Vagrant](vagrantup.com/downloads)
* Install [Virtual Box](https://www.virtualbox.org/)

> Author used Vagrant 1.7.4 and Virtual Box 4.3.34. At that time Vagrant didn't officially support Virtual Box 5.0.

* Run **vagrant plugin install vagrant-turbo** in command prompt to install the plugin.

```
> vagrant plugin install vagrant-turbo
Installing the 'vagrant-turbo' plugin. This can take a few minutes...
Installed the plugin 'vagrant-turbo (0.0.1.pre)'!
```

### Known issues
* `Vagrant could not detect VirtualBox!` - VirtualBox installer didn't add `C:\Program Files\Oracle\VirtualBox` to the system PATH environment variable, fix it manually.

## Configuration

All code listings presented in this document are modifications of `turbo` block from the Vagrantfile provided below.
The beginning and end of the file remain the same and were removed from code listings for better readability.

To get a complete Vagrantfile paste the code snippet into `turbo` block.
In the example below `turbo` block contains only a comment `TODO: Configure Vagrant Turbo Provisioner`.

```
VAGRANTFILE_API_VERSION = "2"
BASE_BOX = "opentable/win-2012r2-standard-amd64-nocm"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.provider :virtualbox do |v|
    v.gui = true
	v.memory = 4096
  end
  config.vm.box = BASE_BOX
  config.vm.communicator = :winrm
  config.vm.guest = :windows
  config.vm.network :forwarded_port, host: 33389, guest: 3389, id: "rdp", auto_correct: true

  config.vm.provision :turbo do |turbo|
    # TODO: Configure Vagrant Turbo Provisioner
  end
end
```

### Install the latest version of Turbo Plugin
Turbo provisioner always checks whether turbo is installed on guest machine and installs the latest Turbo Plugin release if the tool was not found.

### Login
Operations on containers require login to the Turbo Hub. Provisioner will perform this task if username and password are defined in the login block.

```
turbo.login :b do |b|
    b.username = "username"
    b.password = "password"
end
```

### Manage quota for remote shells
Vagrant executes provisioning using Windows Remote Management (WinRM).
This environment is restricted by a set of quotas including maximum amount of memory allocated per shell.
For more information about quota management for remote shell refer to [MSDN](https://msdn.microsoft.com/en-us/library/windows/desktop/ee309367(v=vs.85).aspx) article.
We recommend to keep the default value of 1024MB for MaxMemoryPerShellMB quota. If your application requires more virtual memory you can change the setting yourself in operating system or configure the provisioner to do so, unless the quota is protected by a Group Policy.

```
turbo.max_memory_per_shell = 2048
```

If the provisioning failed because of System.StackOverFlowException or System.OutOfMemoryException we recommend to increase MaxMemoryPerShellMB quota.

## Development

### Setup
* Install [Ruby 2.0](http://railsinstaller.org/en) or above
* Install [RubyGems 2.5](https://rubygems.org/pages/download#formats) or above
* Confirm that previous steps ran correctly
* Install Gems: Bundler and Rake
```
> ruby --version
> gem --version
> gem install bundler
> bundle --version
> gem install rake
```

### TL;DR
Install plugin dependencies
```
bundle
```
Create Gem package
```
gem build vagrant-turbo.gemspec
```
Run Vagrant command using local build of the plugin
```
bundle exec <Vagrant command>
```

### Release
Update the version number in `version.rb`
Run `rake release`

The program should ask for GitHub credentials to create a Git tag for the version, push local Git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

If you release the plugin for the first time push to rubygems.org may fail because of missing credentials. In that case push the Gem manually.
```
gem push .\pkg\vagrant-turbo-<version>.gem
```

Build locally
```
gem build vagrant-turbo.gemspec
```

Run local build in Vagrant context
```
bundle exec <vagrant command>
```

## License
|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Author:**          | Turbo.net (<support@turbo.net>)
| **Copyright:**       | Copyright (c) 2015 Turbo.net
| **License:**         | Apache License, Version 2.0

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
