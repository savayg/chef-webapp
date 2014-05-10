# NOTE: Cannot set to 'false' if you try to use any app stuff in unicorn.rb
appdefs.unicorn.preload         = true
appdefs.init_script     = "#{app.init_path}/#{app.name}"

appdefs.unicorn.before_fork_user = ''
appdefs.unicorn.after_fork_user = ''

# Set the socket for unicorn app server
appdefs.unicorn.socket          = "#{app.run_path}/#{app.name}.socket"
appdefs.unicorn.workers         = 2