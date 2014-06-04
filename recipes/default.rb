# Create app user
user app.user.name do
  comment   "#{app.name} app user"
  shell     "/bin/bash"
  home      app.user.home
  supports  :manage_home => true
end

# Then the app type
case app.type.downcase
  when 'rails', 'passenger'
    include_recipe 'webapp::rvm'
    include_recipe 'webapp::passenger'

    %w( nginx capistrano cron ssh ).each do |r|
      include_recipe "webapp::#{r}"
    end

  when 'unicorn'
    include_recipe 'webapp::rvm'
    include_recipe 'webapp::unicorn'

    %w( nginx capistrano cron ssh ).each do |r|
      include_recipe "webapp::#{r}"
    end

  when 'nodejs'
    raise "NodeJS support not yet implemented"
  else
    #database only
    #raise "You must specify an application type (hint: passenger, unicorn, nodejs, and so forth)"
end

if app.database
  include_recipe "webapp::db"
end

if app[:monit] && app[:monit][:daemons]
  include_recipe "webapp::monit"
end