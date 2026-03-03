class wingftp_rce::install {
  $secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $user = $secgen_parameters['unix_username'][0]
  $tarball = 'wftpserver-linux-64bit-7.4.3.tar.gz'

  Exec { path => ['/bin', '/usr/bin', '/usr/sbin', '/sbin'] }

  user { $user:
    ensure     => present,
    home       => "/home/${user}",
    managehome => true,
    shell      => '/bin/bash',
  }

  file { '/opt/wftpserver':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "/tmp/${tarball}":
    ensure => file,
    source => "puppet:///modules/wingftp_rce/${tarball}",
    mode   => '0644',
  }

  exec { 'extract-wingftp':
    cwd     => '/opt',
    command => "tar -xzf /tmp/${tarball}",
    creates => '/opt/wftpserver/wftpserver',
    require => [File['/opt/wftpserver'], File["/tmp/${tarball}"]],
  }

  exec { 'cleanup-wingftp-tarball':
    command => "/bin/rm /tmp/${tarball}",
    onlyif  => "/bin/test -f /tmp/${tarball}",
  }
}