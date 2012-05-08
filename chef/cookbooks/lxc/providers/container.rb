#
# Cookbook Name:: lxc
# Provider:: container
#
# Copyright 2012, CrowdFlower, Inc.
#
# All rights reserved - Do Not Redistribute
#

include Chef::Mixin::ShellOut

action :create do
  basedir = new_resource.basedir
  cachedir = "/var/cache/lxc"
  name = new_resource.name
  rootfs = "#{basedir}/#{name}/rootfs"
  config = "#{basedir}/#{name}/config"
  release = new_resource.release
  arch = new_resource.arch
  mirror = new_resource.mirror
  bridge = new_resource.bridge
  variant = new_resource.variant
  
  default_packages = %w(
    apt-utils apt dialog iproute inetutils-ping ssh vim lsb-release locales
  ) #ubuntu-minimal
  
  packages = case release
  when 'lucid'
    %w(resolvconf dhcp3-client gnupg)
  when 'maverick'
    %w(resolvconf dhcp3-client gnupg netbase)
  when 'natty'
    %(resolvconf isc-dhcp-client isc-dhcp-common gnupg netbase)
  else
    %w(isc-dhcp-client isc-dhcp-common gnupg netbase ubuntu-keyring)
  end.push(default_packages).flatten.uniq.join(',')
  
  directory "#{cachedir}/#{release}"
  directory "#{basedir}/#{name}"
  
  
  template config do
    source "lxc-config.erb"
    owner "root"
    group "root"
    mode 0644
    variables({
      :name => name,
      :rootfs => rootfs,
      :bridge => bridge,
      :basedir => basedir,
      :arch => arch
    })
  end
  
  Chef::Log.info "debootstrap --components=main,universe --verbose --variant=#{variant} --arch=#{arch} --include=#{packages} #{release} #{cachedir}/#{release}/rootfs-#{arch} #{mirror}"
  
  bash 'download install' do
    code <<-EOF
      debootstrap --verbose --components=main,universe --variant=#{variant} --arch=#{arch} --include=#{packages} #{release} #{cachedir}/#{release}/rootfs-#{arch} #{mirror}
      # mv "#{cachedir}/#{release}/partial-#{arch}" "#{cachedir}/#{release}/rootfs-#{arch}"
    EOF
    user 'root'
    not_if { ::File.exists?("#{cachedir}/#{release}/rootfs-#{arch}") }
  end

  
  bash "configure locales" do
    code <<-EOF
      chroot #{rootfs} apt-get install --force-yes -y language-pack-en
      chroot #{rootfs} locale-gen en_US.UTF-8
      chroot #{rootfs} update-locale LANG="en_US.UTF-8" LANGUAGE="en_US.UTF-8" LC_ALL="en_US.UTF-8"
    EOF
    action :nothing
  end
  
  bash "disable services" do
    code <<-EOF
      chroot #{rootfs} /usr/sbin/update-rc.d -f umountfs remove
      chroot #{rootfs} /usr/sbin/update-rc.d -f hwclock.sh remove
      chroot #{rootfs} /usr/sbin/update-rc.d -f hwclockfirst.sh remove
      chroot #{rootfs} /usr/sbin/update-rc.d -f ondemand remove
      chroot #{rootfs}rootfs /bin/bash -c 'cd /etc/init; for f in $(ls u*.conf); do mv $f $f.orig; done'
      chroot #{rootfs} /bin/bash -c 'cd /etc/init; for f in $(ls tty[2-9].conf); do mv $f $f.orig; done'
      chroot #{rootfs} /bin/bash -c 'cd /etc/init; for f in $(ls plymouth*.conf); do mv $f $f.orig; done'
      chroot #{rootfs} /bin/bash -c 'cd /etc/init; for f in $(ls hwclock*.conf); do mv $f $f.orig; done'
      chroot #{rootfs} /bin/bash -c 'cd /etc/init; for f in $(ls module*.conf); do mv $f $f.orig; done'
    EOF
    action :nothing
  end
  
  bash "twiddle network" do
    code <<-EOF
      sed -i 's/^.*emission handled.*$/echo Emitting lo/' #{rootfs}/etc/network/if-up.d/upstart
    EOF
    action :nothing
    not_if { release == 'lucid' }
  end
  
  bash 'modify upstart' do
    code <<-EOF
      sed -i 's/start on filesystem and net-device-up IFACE=lo/start on filesystem #and net-device-up IFACE=lo/' #{rootfs}/etc/init/rc-sysinit.conf
    EOF
    action :nothing
  end
  
  bash 'install lxcguest' do
    code <<-EOF
      if [ #{release} = "lucid" -o #{release} = "maverick" ]; then
        chroot #{rootfs} apt-get install --force-yes -y python-software-properties
        chroot #{rootfs} add-apt-repository ppa:ubuntu-virt/ppa
        chroot #{rootfs} apt-get update
      fi
      chroot #{rootfs} apt-get install --force-yes -y lxcguest
    EOF
    action :nothing
  end
  
  bash "reset root password" do
    code "sed -i 's%^root:.*%root:$6$EEGUnn6e$DkpHEGpLyyFW/QePxZjsTvix9E7c8YPdH6RF4BYx8yagQMySPYkmjKMPLyrE7ZpNxUh0huqMCfSLcIct7/puH/:15248:0:99999:7:::%' #{rootfs}/etc/shadow"
    action :nothing
  end
  
  bash "create container" do
    code "/usr/bin/lxc-create -n #{new_resource.name} -f #{config}"
    action :nothing
  end

  bash 'copy install' do
    code <<-EOF
      rsync -av #{cachedir}/#{release}/rootfs-#{arch}/ #{rootfs}/
    EOF
    notifies :run, resources(:bash => "disable services"), :delayed
    notifies :run, resources(:bash => "configure locales"), :delayed
    notifies :run, resources(:bash => "disable services"), :delayed
    notifies :run, resources(:bash => "twiddle network"), :delayed
    notifies :run, resources(:bash => "modify upstart"), :delayed
    notifies :run, resources(:bash => "install lxcguest"), :delayed
    notifies :run, resources(:bash => "reset root password"), :delayed
    notifies :run, resources(:bash => "create container"), :delayed
    not_if { ::File.exists?(rootfs)}
  end
  
  directory "#{rootfs}/selinux"
  
  file "#{rootfs}/selinux/enforce" do
    content "0"
  end
  
  cookbook_file "#{rootfs}/etc/fstab" do
    source "container/etc-fstab"
    owner "root"
    group "root"
    mode 0644
  end
  
  cookbook_file "#{rootfs}/etc/network/interfaces" do
    source "container/interfaces"
    owner "root"
    group "root"
    mode 0644
  end
  
  template "#{rootfs}/etc/dhcp3/dhclient.conf" do
    source "container/dhclient.conf.erb"
    owner "root"
    group "root"
    mode 0644
    variables({
      :name => name
    })
  end
    
  cookbook_file "#{rootfs}/etc/ssh/sshd_config" do
    source "container/sshd_config"
    owner "root"
    group "root"
    mode 0644
  end

  cookbook_file "#{rootfs}/lib/init/fstab" do
    source "container/fstab"
    owner "root"
    group "root"
    mode 0644
  end
  
  cookbook_file "#{rootfs}/etc/init/lxc.conf" do
    source "container/upstart-lxc"
    owner "root"
    group "root"
    mode 0644
  end
  
  cookbook_file "#{rootfs}/etc/init/ssh.conf" do
    source "container/upstart-ssh"
    owner "root"
    group "root"
    mode 0644
  end
  
  # cookbook_file "#{rootfs}/etc/init/console.conf" do
  #   source "container/upstart-ssh"
  #   owner "root"
  #   group "root"
  #   mode 0644
  # end
  
  directory "#{rootfs}/var/run/network" do
    recursive true
  end
  
  file "#{rootfs}/var/run/network/ifstate"
  
  directory "#{rootfs}/var/run/sshd"
end

action :start do
  execute "start container" do
    command "/usr/bin/lxc-start -n #{new_resource.name} -d"
  end
end
