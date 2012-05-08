#
# Cookbook Name:: lxc
# Recipe:: tools
#
# Copyright 2012, CrowdFlower, Inc.
#
# All rights reserved - Do Not Redistribute
#

package "git-core"

git "/usr/local/lxc-tools" do
  repository "https://github.com/phbaer/lxc-tools.git"
  action :sync
end
