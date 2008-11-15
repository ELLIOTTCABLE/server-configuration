raise 'Run this file with `sudo god -c /srv/conf/god.god`... or load it from' +
      'within a running god instance with `sudo god load /srv/conf/god.god`' unless
        Object.const_defined? :God

raise "Your god instance isn't running as root. Restart it." unless
  Process.uid == 0

SRV = '/srv'    unless Object.const_defined? :SRV
USR = 'deploy'  unless Object.const_defined? :USR
GRP = 'http'    unless Object.const_defined? :GRP

Dir['/srv/conf/god/**/*.rb'].each do |file|
  LOG.warn "Loading configuration file #{file}"
  load file
end