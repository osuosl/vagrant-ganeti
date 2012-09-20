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

