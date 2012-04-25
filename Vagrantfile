Vagrant::Config.run do |config|

    config.vm.define :node1 do |config|
        config.vm.host_name = "node1.example.org"
        config.vm.box       = "ganeti"
        config.vm.box_url   = "http://ftp.osuosl.org/pub/osl/ganeti-tutorial/ganeti.box"
        config.vm.network(:hostonly, "33.33.33.11", :adapter => 2)
        config.vm.network(:hostonly, "33.33.34.11", :adapter => 3)
    end

    config.vm.define :node2 do |config|
        config.vm.host_name = "node2.example.org"
        config.vm.box       = "ganeti"
        config.vm.box_url   = "http://ftp.osuosl.org/pub/osl/ganeti-tutorial/ganeti.box"
        config.vm.network(:hostonly, "33.33.33.12", :adapter => 2)
        config.vm.network(:hostonly, "33.33.34.12", :adapter => 3)
    end

  # config.vm.provision :puppet do |puppet|
  #   puppet.manifests_path = "manifests"
  #   puppet.manifest_file  = "ganeti-base.pp"
  # end

end
