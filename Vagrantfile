Vagrant.configure("2") do |config|
  config.vm.box = "debian/bookworm64"

  config.vm.define "tokyo" do |tokyo|
    tokyo.vm.hostname = "tokyo"
    tokyo.vm.network "private_network", ip: "172.16.10.11"
  end

  config.vm.define "yokohama" do |yokohama|
    yokohama.vm.hostname = "yokohama"
    yokohama.vm.network "private_network", ip: "172.16.10.12"
  end

  config.vm.define "osaka" do |osaka|
    osaka.vm.hostname = "osaka"
    osaka.vm.network "private_network", ip: "172.16.10.13"
  end
end
