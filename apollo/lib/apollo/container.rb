require 'active_attr'

module Apollo
  class Container
    include ActiveAttr::Model
    # include Celluloid
  
    attribute :name, :type => String
    attribute :state, :default => :off
    attribute :env, :type => Object, :default => {}
    attribute :packages, :type => Object, :default => [ 'ubuntu-minimal' ]
    attribute :suite, :type => String, :default => 'lucid'
    attribute :mirror, :type => String, :default => "http://archive.ubuntu.com/ubuntu"
    
    def create
      cmd = "/usr/sbin/debootstrap --verbose --variant=minbase --include #{packages.join(',')} #{suite} #{target} #{mirror}"
      self.state = :created
      write "lib/init/fstab", <<-EOS
      # nothing
      EOS

      # Disable unneeded services
      sh "rm -f etc/init/ureadahead*"
      sh "rm -f etc/init/plymouth*"
      sh "rm -f etc/init/hwclock*"
      sh "rm -f etc/init/hostname*"
      sh "rm -f etc/init/*udev*"
      sh "rm -f etc/init/module-*"
      sh "rm -f etc/init/mountall-*"
      sh "rm -f etc/init/mounted-*"
      sh "rm -f etc/init/dmesg*"
      sh "rm -f etc/init/network-*"
      sh "rm -f etc/init/procps*"
      sh "rm -f etc/init/rcS*"
      sh "rm -f etc/init/rsyslog*"

      # Don't run ntpdate when container network comes up
      sh "rm -f etc/network/if-up.d/ntpdate"

      # Don't run cpu frequency scaling
      sh "rm -f etc/rc*.d/S*ondemand"

      # Disable selinux
      write "selinux/enforce", 0

      # Remove console related upstart scripts
      sh "rm -f etc/init/tty*"
      sh "rm -f etc/init/console-setup.conf"

      dev_entries = [
        %w{console},
        %w{fd stdin stdout stderr},
        %w{random urandom},
        %w{null zero} ].flatten

      # Remove everything from /dev unless whitelisted
      Dir["dev/*"].each { |e|
        unless dev_entries.include? File.basename(e)
          sh "rm -rf #{e}"
        end
      }
    end
  
    def start
      self.state = :started
    end
  
    def stop
      self.state = :stopped
    end
  
    def destroy
      self.state = :off
    end
  
    def report
    end
    
    
    def chroot(path, script=nil)
      options = {}
      cmd = "chroot #{path} env -i /bin/bash"
      r,w = IO.pipe
      
      if script
        script = <<-EOS + script
          . /etc/environment
          export PATH
        EOS
        cmd += " -c #{script}"
        options[:out] = w
      end
      pid = spawn(cmd, options)
      Process.waitpid(pid)
      
      if script
        unless $?.exitstatus == 0
          raise "non-zero exit status"
        end
        w.close
        r.read
      end
      
    ensure
      r.close rescue nil
      w.close rescue nil
    end
    
  end
end