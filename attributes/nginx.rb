appdefs.ssl = false
appdefs.force_ssl = false

if app[:http_auth]
  appdefs.http_auth.realm   = "/"
  appdefs.http_auth.exclude = []
end

appdefs.redirect_urls = []
appdefs.alias_urls = []
appdefs.url = node.fqdn

appdefs[:nginx][:keepalive_timeout] = 65

default[:webapp][:nginx][:user] = 'nobody'
default[:webapp][:nginx][:group] = 'nogroup'
default[:webapp][:nginx][:prefix] = '/usr/local'
default[:webapp][:nginx][:dir] = '/etc/nginx'
default[:webapp][:nginx][:log_dir] = '/var/log/nginx'
default[:webapp][:nginx][:version] = '1.4.4'
# You'll want to set this to avoid re-downloading files (this is correct for version above):
default[:webapp][:nginx][:checksum] = '7c989a58e540'
default[:webapp][:nginx][:configure_flags] = []

# Override these attributes in the nginx cookbook (override in your node via node[:webapp])
override['nginx']['user']  = node[:webapp][:nginx][:user]
override['nginx']['group'] = node[:webapp][:nginx][:group]
override['nginx']['source']['use_existing_user'] = true # Don't create this user
override['nginx']['version'] = node[:webapp][:nginx][:version]
override['nginx']['configure_flags'] = node[:webapp][:nginx][:configure_flags]
override['nginx']['init_style'] = 'upstart'

# Directory prefixes and locations
override['nginx']['source']['prefix'] = node[:webapp][:nginx][:prefix]
override['nginx']['dir'] = node[:webapp][:nginx][:dir]
override['nginx']['log_dir'] = node[:webapp][:nginx][:log_dir]
override['nginx']['binary'] = node[:webapp][:nginx][:prefix] + '/sbin/nginx'

# HTTP modules (must be prefixed by nginx::)
override['nginx']['source']['modules'] = [
  'nginx::http_stub_status_module',
  'nginx::http_ssl_module',
  'nginx::http_gzip_static_module'
]

# Override the source values, as they're going to be calculated wrong (copied from nginx::source attributes file)
override['nginx']['source']['version']                 = node['nginx']['version']
override['nginx']['source']['conf_path']               = "#{node['nginx']['dir']}/nginx.conf"
override['nginx']['source']['sbin_path']               = "#{node['nginx']['source']['prefix']}/sbin/nginx"
override['nginx']['source']['default_configure_flags'] = %W[
                                                          --prefix=#{node['nginx']['source']['prefix']}
                                                          --conf-path=#{node['nginx']['dir']}/nginx.conf
                                                          --sbin-path=#{node['nginx']['source']['sbin_path']}
]

override['nginx']['source']['version']  = node['nginx']['version']
override['nginx']['source']['url']      = "http://nginx.org/download/nginx-#{node['nginx']['source']['version']}.tar.gz"
override['nginx']['source']['checksum'] = node[:webapp][:nginx][:checksum]
