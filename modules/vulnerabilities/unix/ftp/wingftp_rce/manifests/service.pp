class wingftp_rce::service {
  service { 'wftpserver':
    ensure  => running,
    enable  => true,
    require => [
      Class['wingftp_rce::install'],
      Class['wingftp_rce::config'],
    ],
  }
}