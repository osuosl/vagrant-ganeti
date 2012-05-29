set -x
date > /etc/vagrant_box_build_time

yum -y install gcc make gcc-c++ ruby kernel-devel-`uname -r` zlib-devel openssl-devel readline-devel sqlite-devel perl

cat > /etc/yum.repos.d/puppetlabs.repo << EOM
[puppetlabs]
name=puppetlabs
baseurl=http://yum.puppetlabs.com/el/6/products/\$basearch
enabled=1
gpgcheck=0
EOM

cat > /etc/yum.repos.d/epel.repo << EOM
[epel]
name=epel
baseurl=http://epel.osuosl.org/6/\$basearch
enabled=1
gpgcheck=0
EOM

yum -y install puppet facter ruby-devel rubygems
yum -y install git vim
yum -y clean all

# Installing vagrant keys
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
curl -L -o authorized_keys https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub
chown -R vagrant /home/vagrant/.ssh

# Installing the virtualbox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
cd /tmp
curl -L -o VBoxGuestAdditions_$VBOX_VERSION.iso http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso
mount -o loop VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt

rm VBoxGuestAdditions_$VBOX_VERSION.iso

# Add ganeti image
mkdir -p /var/cache/ganeti-instance-image/
wget -O /var/cache/ganeti-instance-image/cirros-0.3.0-x86_64.tar.gz http://staff.osuosl.org/~ramereth/ganeti-tutorial/cirros-0.3.0-x86_64.tar.gz

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

exit
