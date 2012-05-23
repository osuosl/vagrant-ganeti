set -x
date > /etc/vagrant_box_build_time

# Update the box
apt-get -y update
apt-get -y install linux-headers-$(uname -r) build-essential
apt-get -y install zlib1g-dev libssl-dev libreadline5-dev parted
apt-get -y install curl unzip vim git-core lvm2 aptitude
apt-get clean

# Use newer puppet
wget http://apt.puppetlabs.com/puppetlabs-release_1.0-3_all.deb
dpkg -i puppetlabs-release_1.0-3_all.deb
rm puppetlabs-release_1.0-3_all.deb
apt-get -y update
apt-get -y install puppet

# Set up sudo
cp /etc/sudoers /etc/sudoers.orig
sed -i -e 's/%sudo ALL=(ALL) ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

# Install vagrant keys
mkdir -p /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
curl -Lo /home/vagrant/.ssh/authorized_keys \
  'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub'
chmod 0600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# Tweak sshd to prevent DNS resolution (speed up logins)
echo 'UseDNS no' >> /etc/ssh/sshd_config

# The netboot installs the VirtualBox support (old) so we have to remove it
/etc/init.d/virtualbox-ose-guest-utils stop
rmmod vboxguest
aptitude -y purge virtualbox-ose-guest-x11 virtualbox-ose-guest-dkms virtualbox-ose-guest-utils

# Install the VirtualBox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
curl -Lo /tmp/VBoxGuestAdditions_$VBOX_VERSION.iso \
  "http://download.virtualbox.org/virtualbox/$VBOX_VERSION/VBoxGuestAdditions_$VBOX_VERSION.iso"
mount -o loop /tmp/VBoxGuestAdditions_$VBOX_VERSION.iso /mnt
yes|sh /mnt/VBoxLinuxAdditions.run
umount /mnt

# Clean up
apt-get -y remove linux-headers-$(uname -r) build-essential
apt-get -y autoremove

# Setting editors
update-alternatives --set editor /usr/bin/vim.basic

# Configure LVM
echo "configuring LVM"
swapoff -a
parted /dev/sda -- rm 2
parted /dev/sda -- mkpart primary ext2 15GB -1s
parted /dev/sda -- toggle 2 lvm
pvcreate /dev/sda2
vgcreate ganeti /dev/sda2
lvcreate -L 512M -n swap ganeti
mkswap -f /dev/ganeti/swap
sed -i -e 's/sda5/ganeti\/swap/' /etc/fstab

# Add ganeti image
echo "adding ganeti guest image"
mkdir -p /var/cache/ganeti-instance-image/
wget -O /var/cache/ganeti-instance-image/cirros-0.3.0-x86_64.tar.gz http://staff.osuosl.org/~ramereth/ganeti-tutorial/cirros-0.3.0-x86_64.tar.gz

rm /tmp/VBoxGuestAdditions_$VBOX_VERSION.iso 

# Zero out the free space to save space in the final image:
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

# Removing leftover leases and persistent rules
echo "cleaning up dhcp leases"
rm /var/lib/dhcp3/*

# Make sure Udev doesn't block our network
echo "cleaning up udev rules"
rm /etc/udev/rules.d/70-persistent-net.rules
mkdir /etc/udev/rules.d/70-persistent-net.rules
rm -rf /dev/.udev/
rm /lib/udev/rules.d/75-persistent-net-generator.rules

echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
echo "pre-up sleep 2" >> /etc/network/interfaces
exit
