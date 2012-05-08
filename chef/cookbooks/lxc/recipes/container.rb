#
# Cookbook Name:: lxc
# Recipe:: container
#
# Copyright 2012, CrowdFlower, Inc.
#
# All rights reserved - Do Not Redistribute
#


lxc_container "vm0" do
  basedir node['lxc']['basedir']
  bridge node['lxc']['bridge']
  action [ :create ]
  # action [ :create, :start ]
end
