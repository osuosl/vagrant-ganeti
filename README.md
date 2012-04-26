# Vagrant files for a Ganeti tutorial and/or Ganeti testing environment.

Set of [Vagrant](http://vagrantup.com/) files used for deploying a single or
multi-node [Ganeti](http://code.google.com/p/ganeti/) cluster.  The original
goal of this was to provide a testing environment for the [Ganeti Web
Manager](http://code.osuosl.org/projects/ganeti-webmgr) team at the
[OSUOSL](http://osuosl.org). It can also be used as a Ganeti training platform
using a tutorial I have written up. (TODO).

Vagrant will setup up to three Ganeti nodes with the basics to install
[Ganeti](http://code.google.com/p/ganeti/), [Ganeti Instance
Image](http://code.osuosl.org/projects/ganeti-image), and [Ganeti Web
Manager](http://code.osuosl.org/projects/ganeti-webmgr). You can deploy any
number of nodes for the uses you want. Ganeti will already be initialized on
`node1`.

This was originally used for [Hands on Virtualization with
Ganeti](http://www.oscon.com/oscon2011/public/schedule/detail/18544) at [OSCON
2011](http://oscon.com) and has been adapted for use with Vagrant. The intention
of this is for instructional and testing purposes only.

# Requirements

* VirtualBox >=4.1.12
* vagrant >=1.0.x

# Setup

1. Install VirtualBox by going to their [download
page](https://www.virtualbox.org/wiki/Downloads).

2. Install Vagrant

    `gem install vagrant`

3. Initialize submodule(s)

    `git submodule init`

# Using Vagrant

The Vagrantfile is setup to where you can deploy one, two, or three nodes
depending on your use case. `Node1` will have Ganeti already initialized while
the other two will only have Ganeti installed and primed.

For more information on how to use Vagrant, please [check out their
site](http://vagrantup.com/docs/index.html).

## Starting a single node

    vagrant up node1
    vagrant ssh node1

## Starting node2

NOTE: Root password is 'vagrant'.

    vagrant up node2
    vagrant ssh node1
    gnt-node add -s 33.33.34.12 node2

## Starting node3

NOTE: Root password is 'vagrant'.

    vagrant up node3
    vagrant ssh node1
    gnt-node add -s 33.33.34.13 node3

# Accessing the nodes

All the nodes are using `hostonly` networking with the following IP's:

* ganeti.example.org (cluster IP) = 33.33.33.10
* node1.example.org = 33.33.33.11
* node2.example.org = 33.33.33.12
* node3.example.org = 33.33.33.13
* node1 (drbd) = 33.33.34.11
* node2 (drbd) = 33.33.34.12
* node3 (drbd) = 33.33.34.13

It might be helpful to add the following to your `/etc/hosts` so its easier to
use in GWM.

    33.33.33.10 ganeti.example.org

# Copyright

This work is licensed under a [Creative Commons Attribution-Share Alike 3.0
United States License](http://creativecommons.org/licenses/by-sa/3.0/us/).

vi: set tw=80 ft=markdown :
