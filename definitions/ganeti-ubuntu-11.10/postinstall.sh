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

chroot_cmd() {
    chroot /mnt/gentoo $@
}

if [ -x /usr/bin/lsb_release ] ; then
    OS="$(lsb_release -s -i | tr '[A-Z]' '[a-z]')"
    if [ "$OS" == "centos" ] ; then
        OSRELEASE="$(lsb_release -s -r | sed -e 's/\..*//')"
    else
        OSRELEASE="$(lsb_release -s -c)"
    fi
elif [ -f /etc/redhat-release ] ; then
    OSRELEASE="$(awk '{print $3}' /etc/redhat-release | sed -e 's/\..*//')"
    OS="$(awk '{print tolower($1)}' /etc/redhat-release)"
elif [ -f /etc/gentoo-release ] ; then
    OS="gentoo"
fi

# install puppet
puppet_release="puppetlabs-release-${OSRELEASE}.deb"
wget -q http://apt.puppetlabs.com/${puppet_release}
dpkg -i $puppet_release
rm $puppet_release

$apt update
$apt install puppet facter curl rubygems

# Add vagrant user
if [ ! -d ${rootfs}/home/vagrant ] ; then
    $run_cmd groupadd vagrant
    $run_cmd useradd -d /home/vagrant -s /bin/bash -m -g vagrant vagrant
fi

# Installing vagrant keys
mkdir ${rootfs}/home/vagrant/.ssh
chmod 700 ${rootfs}/home/vagrant/.ssh
wget -q --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub' -O ${rootfs}/home/vagrant/.ssh/authorized_keys
$run_cmd chown -R vagrant /home/vagrant/.ssh

# Ensure passwords are correct
$run_cmd echo "root:vagrant" | chpasswd
$run_cmd echo "vagrant:vagrant" | chpasswd

if [ -f /etc/sudoers ] ; then
    sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
    sed -i "s/^\(.*env_keep = \"\)/\1PATH /" /etc/sudoers
    sed -i -e 's/%admin ALL=(ALL) ALL/%admin ALL=NOPASSWD:ALL/g' /etc/sudoers
    sed -i -e 's/%sudo.*ALL=.*ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers
fi
# VirtualBox Additions

# kernel source is needed for vbox additions
if [ -f /etc/redhat-release ] ; then
    $yum install gcc bzip2 make kernel-devel-$(uname -r)
    $yum install gcc-c++ zlib-devel openssl-devel readline-devel sqlite3-devel
    $yum erase gtk2 libXext libXfixes libXrender hicolor-icon-theme avahi \
        freetype bitstream-vera-fonts
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

# Remove 127.0.1.1 host entry as it confuses ganeti during initialization
sed -i -e 's/127.0.1.1.*//' /etc/hosts

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

    # remove annoying resolvconf package
    DEBIAN_FRONTEND=noninteractive apt-get -y remove resolvconf

    echo "Adding a 2 sec delay to the interface up, to make the dhclient happy"
    echo "pre-up sleep 2" >> /etc/network/interfaces
    # Remove all kernels except the current version
    dpkg-query -l 'linux-image-[0-9]*' | grep ^ii | awk '{print $2}' | \
        grep -v $(uname -r) | xargs -r apt-get -y remove
    apt-get -y clean all
elif [ -f /etc/redhat-release ] ; then
    # Exclude upgrading kernels
    if [ "$OS" == "centos" ] ; then
        sed -i -e 's/\[updates\]/\[updates\]\nexclude=kernel*/' \
            /etc/yum.repos.d/CentOS-Base.repo
    else
        sed -i -e 's/\[updates\]/\[updates\]\nexclude=kernel*/' \
            /etc/yum.repos.d/fedora-updates.repo
    fi
    # Remove all kernels except the current version
    rpm -qa | grep ^kernel-[0-9].* | sort | grep -v $(uname -r) | \
        xargs -r yum -y remove
    yum -y clean all
fi

# Zero out the free space to save space in the final image:
dd if=/dev/zero of=/EMPTY bs=1M
rm -f /EMPTY

exit
