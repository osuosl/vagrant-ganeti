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
