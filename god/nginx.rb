God.watch do |watch|; watch.name = 'nginx'
  
  watch.pid_file = "#{SRV}/temp/pids/#{watch.name}.pid"
        log_file = "#{SRV}/logs/#{watch.name}.log"
  
  watch.interval = 60.seconds
  watch.grace = 10.seconds
  
  watch.start = "nginx -c #{SRV}/conf/nginx.conf -g '\
                  pid #{watch.pid_file};\
                  user #{USR} #{GRP};\
                '"
  
  watch.stop = lambda do
    if File.file? watch.pid_file
      LOG.error("#{watch.name} is missing a PID file - it's probably not running")
    else
      pid = File.read(watch.pid_file).match(/\d+/)[0].to_i
      Process.kill('HUP', pid)
      LOG.warn("#{watch.name} asked to suicide")
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
