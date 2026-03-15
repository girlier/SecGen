class wingftp_rce::config {
  $secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $port = $secgen_parameters['port'][0] ? { undef => 5466, default => $secgen_parameters['port'][0] }
  $leaked_filenames = $secgen_parameters['leaked_filenames']
  $strings_to_leak = $secgen_parameters['strings_to_leak']
  $strings_to_pre_leak = $secgen_parameters['strings_to_pre_leak']
  $pre_leaked_filenames = $secgen_parameters['pre_leaked_filenames']
  $user = $secgen_parameters['unix_username'][0]

  Exec { path => ['/bin', '/usr/bin', '/usr/sbin', '/sbin'] }

  file { '/etc/systemd/system/wftpserver.service':
    ensure  => file,
    content => template('wingftp_rce/wftpserver.service.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    notify  => Exec['systemctl-daemon-reload'],
  }

  exec { 'systemctl-daemon-reload':
    command     => 'systemctl daemon-reload',
    refreshonly => true,
  }

  # Flag 1: Accessible via anonymous FTP (pre-leak in user's home directory)
  ::secgen_functions::leak_files { 'wingftp_rce-file-pre-leak':
    storage_directory => "/home/${user}",
    leaked_filenames  => $pre_leaked_filenames,
    strings_to_leak   => $strings_to_pre_leak,
    leaked_from       => 'wingftp_rce-anon',
    owner             => $user,
    mode              => '0644'
  }

  # Flag 2: Requires RCE to access (in /opt/wftpserver/)
  ::secgen_functions::leak_files { 'wingftp_rce-file-leak':
    storage_directory => '/opt/wftpserver',
    leaked_filenames  => $leaked_filenames,
    strings_to_leak   => $strings_to_leak,
    leaked_from       => 'wingftp_rce',
    owner             => 'root',
    mode              => '0600'
  }
}