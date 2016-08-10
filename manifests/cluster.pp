class midonet::cluster(
  $zk_server_list,
  $management_vip,
  $shared_secret,
  $keystone_admin_token)
{

  $zk_servers = regsubst($zk_server_list, '$', ':2181')

  package {'midonet-cluster':
    ensure  => present,
  } ->

  package {'midonet-tools':
    ensure  => present,
  } ->

  file {'/etc/midonet/midonet.conf':
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('midonet/midonet.conf.erb'),
    notify  => Service['midonet-cluster'],
    require => Package['midonet-cluster'],
  } ->

  exec {'mn-conf-metadata-url':
    command => "mn-conf set -t default 'agent.openstack.metadata.nova_metadata_url : \"http://${management_vip}:8775\"' ; true",
    path    => '/usr/bin:/bin',
    require => Package['midonet-tools'],
  } ->

  exec {'mn-conf-metadata-secret':
    command => "mn-conf set -t default 'agent.openstack.metadata.shared_secret : ${shared_secret}' ; true",
    path    => '/usr/bin:/bin',
    require => Package['midonet-tools'],
  } ->

  exec {'mn-conf-metadata-state':
    command => "mn-conf set -t default 'agent.openstack.metadata.enabled : true' ; true",
    path    => '/usr/bin:/bin',
    require => Package['midonet-tools'],
  } ->

  exec {'mn-conf-replication':
    command => "mn-conf set -t default 'cassandra.replication_factor : 3' ; true",
    path    => '/usr/bin:/bin',
    require => Package['midonet-tools'],
  } ->

  exec {'mn-conf-keystone-admin':
    command => "/bin/echo -e 'cluster.auth {\n    provider_class = \"org.midonet.cluster.auth.keystone.KeystoneService\"\n    admin_role = \"admin\"\n    keystone.tenant_name = \"admin\"\n    keystone.admin_token = \"${keystone_admin_token}\"\n    keystone.host = ${management_vip}\n    keystone.port = 35357\n}' | mn-conf set -t default ; true",
    path    => '/usr/bin:/bin',
    require => Package['midonet-tools'],
  } ->

  service {'midonet-cluster':
    ensure  => running,
    enable  => true,
    require => Package['midonet-cluster'],
  }

}
