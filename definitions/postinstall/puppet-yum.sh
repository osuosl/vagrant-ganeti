# install puppet
cat > /etc/yum.repos.d/puppetlabs.repo << EOM
[puppetlabs]
name=puppetlabs
baseurl=http://yum.puppetlabs.com/el/${OSRELEASE}/products/\$basearch
enabled=1
gpgcheck=0
EOM

cat > /etc/yum.repos.d/epel.repo << EOM
[epel]
name=epel
baseurl=http://epel.osuosl.org/${OSRELEASE}/\$basearch
enabled=1
gpgcheck=0
EOM

$yum install puppet facter
