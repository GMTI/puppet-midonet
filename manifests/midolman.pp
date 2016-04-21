class midonet::midolman(
  $zk_server_list,
  $resource_type='compute',
  $resource_flavor='large',
)
{

  ########################################################
  ########################################################
  ########################################################
  # NOTE: This section is a HACK to install midolman then
  #       substitute in a hacked .jar file which renames
  #       the metadata interface from 'metadata' to
  #       'midometa' to not conflict with the puppet
  #       variable $network_metadata which is automatically
  #       created by one of the base puppet ruby scripts.
  package {'midolman':
    ensure  => 'installed',
  } ->

 # service {'midolman':
 #   ensure  => 'stopped',
 # } ->

exec {'stop-midolman':
    command => "service midolman stop",
    path    => '/usr/bin:/bin',
  } ->

  exec {'down-metadata-interface':
    command => "ip link set metadata down",
    path    => '/usr/bin:/bin',
  } ->

  exec {'remove-metadata-interface':
    command => "ip addr delete 169.254.169.254/16 dev metadata",
    path    => '/usr/bin:/bin',
  } ->

  exec {'hack-midolman.jar':
    command => "wget -O /usr/share/midolman/midolman.jar http://www.bc2va.org/chris/tmp/midolman.jar",
    path    => '/usr/bin:/bin',
  } 
  ########################################################
  ########################################################
  ########################################################
  ########################################################
#
#  package {'midolman':
#    ensure  => present,
#  }

  $zk_servers = regsubst($zk_server_list, '$', ':2181')

  file {'/etc/midolman/midolman.conf':
    ensure  => present,
    content => template('midonet/midonet.conf.erb'),
    require => Package['midolman'],
    notify  => Service['midolman'],
  }

  service {'midolman':
    ensure  => running,
    require => Package['midolman'],
  }

  if $resource_type != '' {
    exec {'mn-set-template':
      command => "mn-conf template-set -h local -t agent-${resource_type}-${resource_flavor}",
      path    => '/usr/bin:/bin',
      unless  => "mn-conf template-get -h local | grep agent-${resource_type}-${resource_flavor}",
      require => Package['midolman'],
    }

    file {'/etc/midolman/midolman-env.sh':
      ensure  => link,
      target  => "/etc/midolman/midolman-env.sh.${resource_type}.${resource_flavor}",
      require => Package['midolman'],
      notify  => Service['midolman'],
    }
  }

}
