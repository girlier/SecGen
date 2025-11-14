class apache_couchdb::couchdb {
  $secgen_parameters=secgen_functions::get_parameters($::base64_inputs_file)
  $username = $secgen_parameters['unix_username'][0]
  $password = $secgen_parameters['used_password'][0]
  $host ='127.0.0.1'
  $docroot = '/opt/couchdb'
  $database_dir = '/var/lib/couchdb'
  $uid = fqdn_uuid('localhost.com')
  $port =  $secgen_parameters['port'][0]

  Exec { path => ['/bin', '/usr/bin', '/usr/local/bin', '/sbin', '/usr/sbin'] }
  
  # Ensure systemd is reloaded for CouchDB service from .deb
  exec { 'systemd-daemon-reload':
    command   => 'systemctl daemon-reload',
    logoutput => true,
  }
  -> user { $username:
    ensure   => present,
    shell    => '/bin/bash',
    password => pw_hash($password, 'SHA-512', 'mysalt'),
  }
  -> exec { 'chown-couchdb':
    command   => "chown -R ${username}:${username} ${docroot}",
    logoutput => true
  }
  -> exec { 'chmod-couchdb':
    command   => "chmod -R 770 ${docroot}",
    logoutput => true
  }
  -> file { "${docroot}/etc/local.ini" :
    ensure  => file,
    content => template('apache_couchdb/local.ini.erb'),
  }
  -> file { "${docroot}/etc/vm.args":
    ensure  => file,
    content => template('apache_couchdb/vm.args.erb'),
  }
  -> exec { 'enable-couchdb':
    command   => 'systemctl enable couchdb',
    logoutput => true,
  }
  -> exec { 'restart-couchdb':
    command   => 'systemctl restart couchdb',
    logoutput => true,
  }
  -> exec { 'wait-apache-couchdb':
    command   => 'sleep 4',
    logoutput => true,
  }
  -> exec { 'chown-uri-file':
    command   => "chown -R ${username}:${username} /var/run/couchdb/",
    logoutput => true,
    onlyif    => 'test -d /var/run/couchdb/',
  }
  -> exec { 'chmod-uri-file':
    command   => 'chmod -R 770 /var/run/couchdb/',
    logoutput => true,
    onlyif    => 'test -d /var/run/couchdb/',
  }
}
