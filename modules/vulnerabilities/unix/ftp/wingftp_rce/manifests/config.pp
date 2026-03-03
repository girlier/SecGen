class wingftp_rce::config {
  $secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $port = $secgen_parameters['port'][0] ? { undef => 5466, default => $secgen_parameters['port'][0] }
  $leaked_filenames = $secgen_parameters['leaked_filenames']
  $strings_to_leak = $secgen_parameters['strings_to_leak']

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

  ::secgen_functions::leak_files { 'wingftp_rce-file-leak':
    storage_directory => '/root',
    leaked_filenames  => $leaked_filenames,
    strings_to_leak   => $strings_to_leak,
    leaked_from       => 'wingftp_rce',
    mode              => '0600'
  }
}