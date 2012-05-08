#
# Cookbook Name:: lxc
# Recipe:: network
#
# Copyright 2012, CrowdFlower, Inc.
#
# All rights reserved - Do Not Redistribute
#

package 'bridge-utils'
package 'dnsmasq'

file '/etc/sysctl.d/33-ip-forward.conf' do
  backup false
  action :create
  content <<-EOF
net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1
net.ipv6.conf.all.proxy_ndp=1
  EOF
end

execute 'activate IP forwarding' do
  command '/etc/init.d/procps start'
  action :nothing
  subscribes :run, resources(:file => '/etc/sysctl.d/33-ip-forward.conf')
end

template '/etc/network/interfaces' do
  source 'interfaces.erb'
  variables({
    :bridge => node['lxc']['bridge'],
    :ipv4 => node['lxc']['ipv4']
  })
end

execute 'activate network bridge' do
  command '/etc/init.d/networking restart'
  action :nothing
  subscribes :run, resources(:template => '/etc/network/interfaces')
end

template '/etc/network/if-up.d/nat-for-bridges' do
  source 'if-up-nat.erb'
  action :create
  mode '0755'
  variables({
    :bridge => node['lxc']['bridge']
  })
end

template '/etc/dnsmasq.conf' do
  source 'dnsmasq.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
end

service "dnsmasq" do
  supports :restart => true
end

template '/etc/dhcp/dhclient.conf' do
  source 'dhclient.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
end

execute 'regenerate-resolv-conf' do
  command 'dhclient3 -e IF_METRIC=100 -pf /var/run/dhclient.eth0.pid -lf /var/lib/dhcp3/dhclient.eth0.leases eth0'
  user 'root'
  action :nothing
  subscribes :run, resources(:template => '/etc/dhcp/dhclient.conf'), :immediately
  notifies :restart, resources(:service => 'dnsmasq'), :immediately
end