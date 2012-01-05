Vagrant::Config.run do |config|

    config.vm.define :node1 do |config|
        config.vm.box     = "ganeti"
        config.vm.network("33.33.33.11")
        config.vm.network("33.33.34.11", {:adapter=>2})
    end

  # config.vm.provision :puppet do |puppet|
  #   puppet.manifests_path = "manifests"
  #   puppet.manifest_file  = "ganeti-base.pp"
  # end

end
