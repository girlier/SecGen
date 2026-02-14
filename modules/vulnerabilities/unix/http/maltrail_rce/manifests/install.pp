# Class: maltrail_rce::install
# Install process for vulnerable MalTrail version 0.53
#
# OFFLINE SUPPORT:
# - MalTrail tarball is bundled locally in files/maltrail-0.53.tar.gz
# - Configuration is bundled locally in files/maltrail.conf
# - System packages (python3, libpcap-dev, etc.) should be pre-installed on base image
# - python3-pcapy is available in Debian 12 (bookworm) repositories
#
# For truly offline environments, ensure the base Debian 12 image has:
#   - python3, python3-pip, python3-dev
#   - libpcap-dev, build-essential
#   - python3-pcapy
# Or use a local apt mirror/pre-cached packages
#
class maltrail_rce::install {
  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }
  $modulename = 'maltrail_rce'

  $secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $port = $secgen_parameters['port'][0]
  $user = $secgen_parameters['unix_username'][0]
  $user_home = "/home/${user}"

  # MalTrail tarball name (single file, no splitting needed)
  $tarball = 'maltrail-0.53.tar.gz'

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

  # Install required packages for MalTrail
  # Note: For offline environments, these should be pre-installed or cached on the base image
  # python3-pcapy is the key dependency for MalTrail's packet capture functionality
  ensure_packages(['python3', 'python3-pip', 'python3-dev', 'libpcap-dev', 'build-essential', 'python3-pcapy'])

  # Create user home directory with proper permissions
  file { $user_home:
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => '0750',
    require => User[$user],
  }

  # OFFLINE: Copy MalTrail tarball
  file { "/tmp/${tarball}":
    ensure => file,
    source => "puppet:///modules/${modulename}/${tarball}",
  }

  # Extract MalTrail tarball (maltrail-0.53 directory format)
  exec { 'extract-maltrail':
    cwd     => '/tmp',
    command => "tar -xzf ${tarball}",
    creates => '/opt/maltrail',
    require => File["/tmp/${tarball}"],
  }

  # Move MalTrail to installation directory
  exec { 'install-maltrail':
    cwd     => '/tmp',
    command => 'mv maltrail-0.53 /opt/maltrail',
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
