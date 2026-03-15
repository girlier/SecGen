class wingftp_rce::service {
  service { 'wftpserver':
    ensure  => running,
    enable  => true,
    require => [
      Class['wingftp_rce::install'],
      Class['wingftp_rce::config'],
    ],
  }

  # Start the domain setup service after Wing FTP is running
  service { 'wftpserver-domain-setup':
    ensure  => running,
    enable  => true,
    require => [
      Service['wftpserver'],
      Class['wingftp_rce::install'],
    ],
  }
}