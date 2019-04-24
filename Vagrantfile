# -*- mode: ruby -*-
# vi: set ft=ruby :


# Make sure required plugins are installed
# ex: required_plugins = %w({:name => "vagrant-hosts", :version => ">= 2.8.0"})
required_plugins = [{:name => "vagrant-hosts", :version => ">= 2.8.0"}, {:name => "vagrant-vbguest", :version => ">= 0.16.0"}]

plugins_to_install = required_plugins.select { |plugin| not Vagrant.has_plugin?(plugin[:name], plugin[:version]) }
if not plugins_to_install.empty?
  plugins_to_install.each { |plugin_to_install|
    puts "Installing plugin: #{plugin_to_install[:name]}, version #{plugin_to_install[:version]}"
    if system "vagrant plugin install #{plugin_to_install[:name]} --plugin-version \"#{plugin_to_install[:version]}\""
    else
      abort "Installation of one or more plugins has failed. Aborting."
    end
  }
  exec "vagrant #{ARGV.join(' ')}"
end

require 'yaml'
conf_file = File.join(File.dirname(__FILE__), 'vagrant_overrides.yaml')
conf = File.exists?(conf_file)? YAML.load_file(conf_file) : {}

MEM_MASTER         = conf['MEM_MASTER'] || 1024
MEM_MINION         = conf['MEM_MINION'] || 512
CPU_MASTER         = conf['CPU_MASTER'] || 1
CPU_MINION         = conf['CPU_MINION'] || 1
GUI                = conf['GUI'] || false
BOX                = conf['BOX'] || "ubuntu/bionic64"
DOMAIN             = conf['DOMAIN'] || ".saltstack.inet"
NETWORK            = conf['NETWORK'] || "192.168.77."
NETMASK            = conf['NETMASK'] || "255.255.255.0"
MINIONS            = conf['MINIONS'] || 1
SALT_VERSION       = conf['SALT_VERSION'] || "2019.2.0"
MINION_EXPOSE_PORT = conf['MINION_EXPOSE_PORT'] || false


Vagrant.configure(2) do |config|
  config.vm.define "master" do |master|
    master.vm.box = BOX
    master.vm.provider "virtualbox" do |vbox|
      vbox.gui = GUI
      vbox.memory = MEM_MASTER
      vbox.cpus = CPU_MASTER
      vbox.name = "master"
    end

    master.vm.hostname = "master" + DOMAIN
    master.vm.network 'private_network', ip: NETWORK + "100", netmask: NETMASK
    master.vm.synced_folder "./salt", "/srv/salt"
    master.vm.provision "file", source: "~/.gitconfig", destination: ".gitconfig"
    master.vm.provision "shell", path: "vagrant/provision/master_#{BOX.gsub('/', '_')}.sh", args: [ NETWORK ]
    master.vm.provision :hosts, :sync_hosts => true
    master.vm.provision :hosts, :add_localhost_hostnames => false

    master.vm.provision :salt do |salt_master|
      salt_master.install_master = true
      salt_master.master_config = "./templates/etc/master"
      salt_master.minion_config = "./templates/etc/minion"
      salt_master.always_install = true
      salt_master.install_type = "stable"
      salt_master.install_args = SALT_VERSION
      salt_master.verbose = true
      salt_master.colorize = true
    end
  end

  (1..MINIONS).each do |node|
    config.vm.define "minion-local-#{node}" do |minion|
      minion.vm.box = BOX
      minion.vm.provider "virtualbox" do |vbox|
        vbox.gui = GUI
        vbox.memory = MEM_MINION
        vbox.cpus = CPU_MINION
        vbox.name = "minion-local-#{node}"
      end

      minion.vm.hostname = "minion-local-#{node}" + DOMAIN
      minion.vm.network 'private_network', ip: NETWORK + "#{node}0", netmask: NETMASK
      config.vm.network "forwarded_port", guest: MINION_EXPOSE_PORT, host: MINION_EXPOSE_PORT if MINION_EXPOSE_PORT
      minion.vm.provision "shell", path: "vagrant/provision/minion_#{BOX.gsub('/', '_')}.sh", args: [ NETWORK ]
      minion.vm.provision :hosts, :sync_hosts => true
      minion.vm.provision :hosts, :add_localhost_hostnames => false

      minion.vm.provision :salt do |salt_minion|
        salt_minion.minion_config = "./templates/etc/minion"
        salt_minion.minion_id = "minion-local-#{node}" + DOMAIN
        salt_minion.always_install = true
        salt_minion.install_type = "stable"
        salt_minion.install_args = SALT_VERSION
        salt_minion.verbose = true
        salt_minion.colorize = true
      end
    end
  end
end
