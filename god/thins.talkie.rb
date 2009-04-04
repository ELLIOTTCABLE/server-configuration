TalkieRoot = "#{SRV}/sites/talkie.me"

(1..2).each do |socket|
  God.watch do |watch|; watch.name = "thins.talkie.#{socket}"
    
    watch.group = "thins.talkie"
    
    watch.pid_file = "#{SRV}/temp/pids/thins.talkie/#{socket}.pid"
       socket_file = "#{SRV}/temp/sockets/thins.talkie/#{socket}.sock"
          log_file = "#{SRV}/logs/thins.talkie/#{socket}.log"
    
    watch.interval = 60.seconds
    watch.grace = 10.seconds
    
    watch.start = ["/usr/lib/ruby/gems/1.8/gems/thin-1.0.0/bin/thin", "start",
                     {:socket => socket_file,
                      :environment => :development,
                      :chdir => TalkieRoot,
                      :rackup => TalkieRoot + "/config.ru",
                      :log => log_file,
                      :pid => watch.pid_file,
                      :stats => "/stats:#{socket}",
                      :timeout => 90,
                      :user => "bluebie",
                      :group => GRP}.map {|k,v|"--#{k} #{v}"}.join(' '),
                  "--threaded",
                  "--no-epoll",
                  "--daemonize"].join(' ')
    
    watch.start += " --debug" if socket == 1 # First thin should always have debugging enabled
    
    watch.restart = lambda do
      if !File.file? watch.pid_file
        LOG.error("#{watch.name} is missing a PID file - it's probably not running")
      else
        pid = File.read(watch.pid_file).match(/\d+/)[0].to_i
        Process.kill('HUP', pid)
        LOG.warn("#{watch.name} asked to refresh (SIGHUP PID #{pid})")
      end
    end
    
    watch.stop = lambda do
      if !File.file? watch.pid_file
        LOG.error("#{watch.name} is missing a PID file - it's probably not running")
      else
        pid = File.read(watch.pid_file).match(/\d+/)[0].to_i
        Process.kill('INT', pid)
        LOG.warn("#{watch.name} asked to suicide (SIGINT PID #{pid})")
      end
    end
    watch.behavior(:clean_pid_file)
    
    watch.start_if do |start|
      start.condition(:process_running) do |condition|
        condition.interval = 5.seconds
        condition.running = false
      end
    end
    
    watch.restart_if do |restart|
      restart.condition(:memory_usage) do |condition|
        condition.above = 75.megabytes
        condition.times = [3, 5] # 3 out of 5 intervals
      end
    
      restart.condition(:cpu_usage) do |condition|
        condition.above = 50.percent
        condition.times = 5
      end
    end
    
    watch.lifecycle do |on|
      on.condition(:flapping) do |condition|
        condition.to_state = [:start, :restart]
        condition.times = 5
        condition.within = 5.minute
        condition.transition = :unmonitored
        condition.retry_in = 10.minutes
        condition.retry_times = 5
        condition.retry_within = 2.hours
      end
    end
    
  end
end
