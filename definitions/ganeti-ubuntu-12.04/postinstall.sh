#!/bin/bash
set -x

export PATH="/bin/:/usr/sbin:/usr/bin:/sbin:${PATH}"
apt="apt-get -qq -y"
yum="yum -q -y"

date > /etc/vagrant_box_build_time

fail()
{
    echo "FATAL: $*"
    exit 1
}

if [ -x /usr/bin/lsb_release ] ; then
    OSRELEASE="$(lsb_release -s -c)"
elif [ -f /etc/redhat-release ] ; then
    OSRELEASE="$(awk '{print $3}' /etc/redhat-release | sed -e 's/\..*//')"
fi

# install puppet
puppet_release="puppetlabs-release-${OSRELEASE}.deb"
wget -q http://apt.puppetlabs.com/${puppet_release}
dpkg -i $puppet_release
rm $puppet_release

$apt update
$apt install puppet facter

# Installing vagrant keys
mkdir /home/vagrant/.ssh
chmod 700 /home/vagrant/.ssh
cd /home/vagrant/.ssh
wget -q --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O authorized_keys
chown -R vagrant /home/vagrant/.ssh

# Ensure passwords are correct
echo "root:vagrant" | chpasswd
echo "vagrant:vagrant" | chpasswd

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
sed -i "s/^\(.*env_keep = \"\)/\1PATH /" /etc/sudoers

# VirtualBox Additions

# kernel source is needed for vbox additions
if [ -f /etc/redhat-release ] ; then
    $yum install gcc bzip2 make kernel-devel-$(uname -r)
    $yum install gcc-c++ zlib-devel openssl-devel readline-devel sqlite3-devel
    $yum erase gtk2 libX11 hicolor-icon-theme avahi freetype bitstream-vera-fonts
elif [ -f /etc/debian_version ] ; then
    $apt install linux-headers-$(uname -r) build-essential dkms
    if [ -f /etc/init.d/virtualbox-ose-guest-utils ] ; then
        # The netboot installs the VirtualBox support (old) so we have to
        # remove it
        /etc/init.d/virtualbox-ose-guest-utils stop
        rmmod vboxguest
        $apt purge virtualbox-ose-guest-x11 virtualbox-ose-guest-dkms \
            virtualbox-ose-guest-utils
    elif [ -f /etc/init.d/virtualbox-guest-utils ] ; then
        /etc/init.d/virtualbox-guest-utils stop
        $apt purge virtualbox-guest-utils virtualbox-guest-dkms virtualbox-guest-x11
    fi
fi

# Installing the virtualbox guest additions
VBOX_VERSION=$(cat /home/vagrant/.vbox_version)
VBOX_ISO=/home/vagrant/VBoxGuestAdditions_${VBOX_VERSION}.iso
cd /tmp

if [ ! -f $VBOX_ISO ] ; then
    wget -q http://download.virtualbox.org/virtualbox/${VBOX_VERSION}/VBoxGuestAdditions_${VBOX_VERSION}.iso \
        -O $VBOX_ISO
fi
mount -o loop $VBOX_ISO /mnt
sh /mnt/VBoxLinuxAdditions.run
umount /mnt

rm $VBOX_ISO

if [ -f /etc/redhat-release ] ; then
    $yum remove kernel-devel-$(uname -r)
    $yum clean all
elif [ -f /etc/debian_version ] ; then
    $apt remove linux-headers-$(uname -r)
    $apt autoremove
fi

# Setup ganeti

if [ -f /etc/debian_version ] ; then
    $apt install vim git-core lvm2 aptitude nfs-common parted

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
elif [ -f /etc/redhat-release ] ; then
    $yum install git vim nfs-utils
fi

# Install ganeti deps
git clone -q git://github.com/ramereth/vagrant-ganeti.git
cd vagrant-ganeti
git submodule -q update --init
ln -s $(pwd) /vagrant
puppet apply --modulepath=modules modules/ganeti_tutorial/nodes/install-deps.pp
cd
rm -rf vagrant-ganeti
rm -f /vagrant

# cleanup

if [ -f /etc/debian_version ] ; then
    # Removing leftover leases and persistent rules
    echo "cleaning up dhcp leases"
    rm /var/lib/dhcp3/*

    # Make sure Udev doesn't block our network
    # http://6.ptmc.org/?p=164
    echo "cleaning up udev rules"
    rm /etc/udev/rules.d/70-persistent-net.rules
    mkdir /etc/udev/rules.d/70-persistent-net.rules
    rm -rf /dev/.udev/
    rm /lib/udev/rules.d/75-persistent-net-generator.rules

    echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
    echo "pre-up sleep 2" >> /etc/network/interfaces
    apt-get -y clean all
elif [ -f /etc/redhat-release ] ; then
    yum -y clean all
fi

# Zero out the free space to save space in the final image:
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

exit
