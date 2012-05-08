directory '/cgroup'

execute 'mount-cgroup' do
  command 'mount none -t cgroup /cgroup'
  user 'root'
  not_if 'mount | grep cgroup'
end

execute 'add-cgroup-to-fstab' do
  command 'echo "none /cgroup cgroup defaults 0 0" >> /etc/fstab'
  user 'root'
  action :nothing
  subscribes :run, resources(:execute => 'mount-cgroup'), :immediately
end
