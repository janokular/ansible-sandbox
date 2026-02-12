Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  config.vm.define "server00" do |server00|
    server00.vm.hostname = "server00"
    server00.vm.network "private_network", ip: "172.16.10.11"
  end

  config.vm.define "server01" do |server01|
    server01.vm.hostname = "server01"
    server01.vm.network "private_network", ip: "172.16.10.12"
  end

  config.vm.define "server02" do |server02|
    server02.vm.hostname = "server02"
    server02.vm.network "private_network", ip: "172.16.10.13"
  end
end
