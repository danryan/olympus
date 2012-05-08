# # common.rb #
# 
# stuff what's necessary
# 

module C2
  module CLI
    def appname
      File.basename $0
    end

    def alert( msg )
      if system "which -s growlnotify"
        system("growlnotify -s -m #{msg}")
      end
      log msg
    end

    def log( msg )
      $stdout.puts "[#{appname}] #{msg}"
    end
  end
end

=begin
function attempt {
  cmd_name=${name:-In $0, $@ }
  if $@
  then
    say "$cmd_name successful"
  else
    say "$cmd_name failed!"
  fi
}
=end
