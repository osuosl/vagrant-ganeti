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

* VirtualBox >=4.1.x
* vagrant >=1.0.3

# Setup

1. Install VirtualBox by going to their [download
page](https://www.virtualbox.org/wiki/Downloads).

2. Install Vagrant

    `gem install vagrant`

3. Initialize submodule(s)

    `./update`

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

Add the following to your `/etc/hosts` files for easier access locally.

    33.33.33.10 ganeti.example.org
    33.33.33.11 node1.example.org
    33.33.33.12 node2.example.org
    33.33.33.13 node3.example.org

All the nodes are using `hostonly` networking with the following IP's:

* ganeti.example.org (cluster IP) = 33.33.33.10
* node1.example.org = 33.33.33.11
* node2.example.org = 33.33.33.12
* node3.example.org = 33.33.33.13

Additionally, I have setup several VM DNS names in the `/etc/hosts` of each
node that you can use:

* instance1.example.org
* instance2.example.org
* instance3.example.org
* instance4.example.org

# RAPI Access

The RAPI user setup for use on the cluster uses the following credentials.

* user: vagrant
* pass: vagrant

# Running different Ganeti versions

This repo has been setup to deal with a variety of Ganeti versions for testing.
Currently it only supports 2.4.x, 2.5.x, 2.6.x and any git tagged releases.
*Currently 2.7.x is not supported but will be soon.* To switch between the
versions do the following:

- edit `modules/ganeti_tutorial/node{1-3}.pp`
- if using git, change `git` to `true`
- change `ganeti_version` to desired version
- redeploy the vm(s) (destroy, up)

# Node Operating System

By default we use Ubuntu 12.04 for our node OS but we do have support for the
following operating systems. Just run the vagrant commands from inside the
appropriate folder.

* Ubuntu 11.10 (ubuntu-11.10)
* Ubuntu 12.04 (ubuntu-12.04)
* Ubuntu 12.10 (ubuntu-12.10)
* Ubuntu 13.04 (ubuntu-13.04) (work in progress)
* Debian 6 (debian-6)
* Debian 7 (debian-7) (pre-release)
* CentOS 6 (centos-6)
* CentOS 5 (work in progress)

# Deploying Ganeti Web Manager (GWM)

**NOTE: This is currently broken. Please avoid trying this for now**

This repo also supports automatically deploying GWM inside of the `node1`
instance. You can achieve this by changing the puppet manifest for node1 to
point to `node1-gwm.pp` instead.

**NOTE: This is still not quite working right. I hope to have this fixed with
the 0.9 release of GWM**

# Copyright

This work is licensed under a [Creative Commons Attribution-Share Alike 3.0
United States License](http://creativecommons.org/licenses/by-sa/3.0/us/).

vi: set tw=80 ft=markdown :
