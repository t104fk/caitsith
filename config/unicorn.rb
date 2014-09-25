worker_processes 2
timeout 30
listen 3000

pid File.expand_path('../../log/unicorn.pid', __FILE__)
stderr_path File.expand_path('../../log/unicorn_err.log', __FILE__)
stdout_path File.expand_path('../../log/unicorn_stg.log', __FILE__)

preload_app true
GC.respond_to?(:copy_on_write_friendly=) and
  GC.copy_on_write_friendly = true

check_client_cknnection false

before_fork do |server, worker|
  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
  old_pid = "#{server.config[:pid]}.oldbin"
  if old_pid != server.pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      puts "Sending #{sig} signal to old unicorn master..."
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
  sleep 1
end

after_fork do |server, worker|
  GC.disable
  defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
end

