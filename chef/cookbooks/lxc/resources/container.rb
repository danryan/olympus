#
# Cookbook Name:: lxc
# Resource:: container
#
# Copyright 2012, CrowdFlower, Inc.
#
# All rights reserved - Do Not Redistribute
#

actions :create, :destroy, :start, :stop, :freeze, :restart, :unfreeze

packages = %w(
  ifupdown locales netbase net-tools iproute openssh-server dhcp3-client gpgv adduser
  apt-utils vim openssh-blacklist openssh-blacklist-extra console-setup sudo
  iputils-ping aptitude ubuntu-minimal
)

attribute :name, :kind_of => String, :name_attribute => true
# attribute :rootfs, :kind_of => String
attribute :basedir, :kind_of => String, :default => '/mnt/lxc'
attribute :variant, :kind_of => String, :default => 'minbase'
attribute :release, :kind_of => String, :default => 'lucid'
attribute :arch, :kind_of => String, :default => 'amd64', :equal_to => ['amd64', 'i686']
# attribute :packages, :kind_of => Array, :default => packages
attribute :ip_address, :kind_of => String
attribute :bridge, :kind_of => String, :default => 'br0'
attribute :mirror, :kind_of => String, :default => "http://archive.ubuntu.com/ubuntu"
attribute :run_list, :kind_of => Array, :default => []

# def initialize(*args)
#   super
#   @action = :create
# end
