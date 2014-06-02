db_conf = Hash[app.database]
db_conf.delete 'environments'
db_conf['database'] = db_conf.delete 'name'

db_conf.delete('slaves')
db_type = db_conf.delete('type').downcase

if ['localhost', '127.0.0.1', app.private_ip].include?(app.database.host) || (app[:postgresql] && app.postgresql[:nodes])
  # create database user
  case db_type
    when /^postgres/
      if %w(localhost 127.0.0.1).include? app.database.host
        db_conf.delete 'host'
      end

      include_recipe 'postgresql::server'

      psql_create_user      app.user.name
      psql_create_database  app.database.name do
        owner app.user.name
      end

      if app[:postgresql] && app.postgresql[:nodes]
        if app.private_ip == app.database.host #master

          file "/tmp/postgresql.trigger.5432" do
            owner app.user.name
            group app.user.group
            mode  0600
            action :touch
            only_if do
              File.exists?("#{node['postgresql']['config']['data_directory']}/recovery.conf")
            end
          end

        else                                 #slave
          service 'postgresql' do
            action :stop
          end

          file "/tmp/postgresql.trigger.5432" do
            action :delete
          end

          execute "setup initial database" do
            command "rm -R #{node['postgresql']['config']['data_directory']}/* && pg_basebackup -D #{node['postgresql']['config']['data_directory']} --host=#{app[:database][:host]} --port=#{node['postgresql']['config']['port']}"
            creates "#{node['postgresql']['config']['data_directory']}/recovery.conf"
            user      "postgres"
          end

          template "#{node['postgresql']['config']['data_directory']}/recovery.conf" do
            source "recovery.conf.erb"
            owner "postgres"
            group "postgres"
            mode 0600
          end

          service 'postgresql' do
            action :start
          end
        end
      end
    else
      raise "You must specify a valid database type in your application config"
  end

  # Ensure monit has a monitor of the DB
  template "/etc/monit/conf.d/#{db_type}.conf" do
    source "monit/#{db_type}.conf.erb"
    owner 'root'
    group 'root'
    mode  0644
    notifies :reload, 'service[monit]', :delayed
  end
else
  include_recipe 'postgresql'
end

template "#{app.config_path}/database.yml" do
  source "database.yml.erb"
  variables({
                db_conf: db_conf
            })
  owner app.user.name
  group app.user.group
  mode 0600
  only_if do
    File.exists?(app.config_path)
  end
end