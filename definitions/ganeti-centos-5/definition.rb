Veewee::Session.declare({
  :cpu_count => '2',
  :memory_size=> '512',
  :disk_size => '40960',
  :disk_format => 'VDI', :hostiocache => 'off',
  :os_type_id => 'RedHat_64',
  :iso_file => "CentOS-5.9-x86_64-bin-DVD-1of2.iso",
  :iso_src => "http://centos.osuosl.org/5.9/isos/x86_64/CentOS-5.9-x86_64-bin-DVD-1of2.iso",
  :iso_md5 => `curl -s http://centos.osuosl.org/5.9/isos/x86_64/md5sum.txt -o - | awk '{if ( $2 == \"CentOS-5.9-x86_64-bin-DVD-1of2.iso\") print $1 }'`.strip,
  :iso_download_timeout => 1000,
  :boot_wait => "10", :boot_cmd_sequence => [
    '<Tab> text ks=http://%IP%:%PORT%/ks.cfg<Enter>'
  ],
  :kickstart_port => "7122", :kickstart_timeout => 10000,
  :kickstart_file => "ks.cfg",
  :ssh_login_timeout => "10000",
  :ssh_user => "vagrant",
  :ssh_password => "vagrant",
  :ssh_key => "",
  :ssh_host_port => "7222",
  :ssh_guest_port => "22",
  :sudo_cmd => "echo '%p'|sudo -S sh '%f'",
  :shutdown_cmd => "/sbin/halt -h -p",
  :postinstall_files => [ "postinstall.sh"],
  :postinstall_timeout => 10000
})
