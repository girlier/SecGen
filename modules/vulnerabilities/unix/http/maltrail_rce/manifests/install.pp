# Class: maltrail_rce::install
# Install process for vulnerable MalTrail version 0.54
class maltrail_rce::install {
  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }
  $modulename = 'maltrail_rce'

  $secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $port = $secgen_parameters['port'][0]
  $user = $secgen_parameters['unix_username'][0]
  $user_home = "/home/${user}"

  # MalTrail tarball name (single file, no splitting needed)
  $tarball = 'maltrail-0.54.tar.gz'

  # pcapy-ng wheel filename (update version as needed)
  $pcapy_wheel = 'pcapy_ng-0.11.5-py3-none-any.whl'

  # Create dedicated user for MalTrail service
  user { $user:
    ensure     => present,
    home       => $user_home,
    managehome => true,
    shell      => '/bin/bash',
  }

  group { $user:
    ensure => present,
  }

  # Install required packages (no git needed for offline)
  ensure_packages(['python3', 'python3-pip', 'python3-dev', 'libpcap-dev', 'build-essential'])

  # Create user home directory with proper permissions
  file { $user_home:
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => '0750',
    require => User[$user],
  }

  # OFFLINE: Install pcapy-ng from bundled wheel
  file { "/tmp/${pcapy_wheel}":
    ensure => file,
    source => "puppet:///modules/${modulename}/${pcapy_wheel}",
  }

  exec { 'install-pcapy-ng':
    command => "pip3 install /tmp/${pcapy_wheel}",
    unless  => 'python3 -c "import pcapy" 2>/dev/null',
    require => File["/tmp/${pcapy_wheel}"],
  }

  # OFFLINE: Copy MalTrail tarball
  file { "/tmp/${tarball}":
    ensure => file,
    source => "puppet:///modules/${modulename}/${tarball}",
  }

  # Extract MalTrail tarball
  exec { 'extract-maltrail':
    cwd     => '/tmp',
    command => "tar -xzf ${tarball}",
    creates => '/tmp/maltrail-0.54',
    require => File["/tmp/${tarball}"],
  }

  # Move MalTrail to installation directory
  exec { 'install-maltrail':
    cwd     => '/tmp',
    command => 'mv maltrail-0.54 /opt/maltrail',
    creates => '/opt/maltrail',
    require => Exec['extract-maltrail'],
  }

  # Set ownership
  exec { 'chown-maltrail':
    command => "chown -R ${user}:${user} /opt/maltrail",
    require => Exec['install-maltrail'],
  }

  # Copy custom configuration file
  file { '/opt/maltrail/maltrail.conf':
    ensure  => file,
    source  => "puppet:///modules/${modulename}/maltrail.conf",
    owner   => $user,
    group   => $user,
    mode    => '0644',
    require => Exec['install-maltrail'],
  }

  # Configure port in maltrail.conf
  exec { 'configure-port':
    command => "sed -i 's/HTTP_PORT = .*/HTTP_PORT = ${port}/' /opt/maltrail/maltrail.conf",
    require => File['/opt/maltrail/maltrail.conf'],
  }
}
