class apache_couchdb::install {
  $secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $responsefile = 'installresponse'
  $jsondb = 'sampledata.json'
  $password = $secgen_parameters['used_password'][0]

  Exec { path => ['/bin', '/usr/bin', '/usr/local/bin', '/sbin', '/usr/sbin'] }

  # Add Buster repository to fix Debian 12 compatibility
  # This provides the necessary Erlang and SpiderMonkey packages
  file { '/etc/apt/sources.list.d/buster.list':
    ensure  => file,
    content => "deb http://172.33.0.44/deb.debian.org/debian buster main contrib non-free\n",
  }
  -> exec { 'apt-update-buster':
    command => 'apt-get update',
  }
  -> file { "/usr/local/src/couchdb_3.2.1_buster_amd64.deb" :
    ensure => file,
    source => "puppet:///modules/apache_couchdb/couchdb_3.2.1_buster_amd64.deb",
  }
  -> exec { 'install-couchdb-deb':
    command => "dpkg -i /usr/local/src/couchdb_3.2.1_buster_amd64.deb; apt-get install -f -y",
    creates => '/opt/couchdb/bin/couchdb',
  }
  -> file { "/usr/bin/${responsefile}" :
    ensure  => file,
    content => template("apache_couchdb/${responsefile}.erb"),
  }
  -> file { "/usr/bin/${jsondb}.json" :
    ensure  => file,
    content => template("apache_couchdb/${jsondb}.erb"),
  }
}