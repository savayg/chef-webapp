app[:monit][:daemons].each do |daemon|
  template "/etc/monit/conf.d/#{daemon.name}.conf" do
    source "monit/rake.conf.erb"
    variables({
                init_script: daemon.name
              })
    owner 'root'
    group 'root'
    mode  0644
    notifies :reload, 'service[monit]', :delayed
  end

  template "#{app.init_path}/#{daemon.name}" do
    source "rake_init.erb"
    variables({
                init_script: daemon.name,
                daemon: daemon
              })
    mode 0755
  end
end