# Ensure nginx is loaded before continuing
include_recipe 'webapp::nginx'
include_recipe 'webapp::capistrano' #to create the init_path folder

template app.init_script do
  source "unicorn_init.erb"
  mode 0755
end

# Finally ensure monit has a nginx config
template "/etc/monit/conf.d/#{app.name}_unicorn.conf" do
  source 'monit/unicorn.conf.erb'
  owner 'root'
  group 'root'
  mode  0644
  notifies :reload, 'service[monit]', :delayed
end

app.unicorn.workers.times do |w|
  template "/etc/monit/conf.d/#{app.name}_unicorn_worker_#{w}.conf" do
    source 'monit/unicorn_worker.conf.erb'
    owner 'root'
    group 'root'
    mode  0644
    variables({ worker_id: w })
    notifies :reload, 'service[monit]', :delayed
  end
end

unicorn_config "#{app.config_path}/unicorn.rb" do
  preload_app         app.unicorn.preload
  copy_on_write       true
  worker_timeout      30
  worker_processes    app.unicorn.workers
  listen app.unicorn.socket => {
      backlog: 100
  }
  pid                 "#{app.run_path}/unicorn.pid"
  stderr_path         "#{app.log_path}/unicorn.stderr.log"
  stdout_path         "#{app.log_path}/unicorn.stdout.log"
  working_directory   app.current_path
  owner               app.user.name
  group               app.user.name

  before_exec <<-END # do
    Dotenv.overload
  END

  before_fork <<-END # do |server, worker|
    if defined? ActiveRecord::Base
      ActiveRecord::Base.connection.disconnect!
    end

    #{app.unicorn.before_fork_user.is_a?(Array) ? app.unicorn.before_fork_user.join("\n    ") : app.unicorn.before_fork_user}

    old_pid = "\#{server.config[:pid]}.oldbin"
    if old_pid != server.pid
      begin
        sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
        Process.kill(sig, File.read(old_pid).to_i)
      rescue Errno::ENOENT, Errno::ESRCH
      end
    end
  END

  after_fork <<-END # do |server, worker|
    if defined? ActiveRecord::Base
      ActiveRecord::Base.establish_connection
    end

    #{app.unicorn.after_fork_user.is_a?(Array) ? app.unicorn.after_fork_user.join("\n    ") : app.unicorn.after_fork_user}

  END
end