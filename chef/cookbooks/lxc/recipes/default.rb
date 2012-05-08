#
# Cookbook Name:: lxc
# Recipe:: default
#
# Copyright 2012, CrowdFlower, Inc.
#
# All rights reserved - Do Not Redistribute
#

package "debootstrap"
package "lxc"

# include_recipe "lxc::tools"
include_recipe "lxc::cgroup"
include_recipe "lxc::network"
include_recipe "lxc::storage"