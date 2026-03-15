class wingftp_rce (
  $port = undef,
  $strings_to_leak = [],
  $leaked_filenames = [],
  $unix_username = 'ftpuser',
  $admin_password = undef,
) {
  include wingftp_rce::install
  include wingftp_rce::config
  include wingftp_rce::service

  Class['wingftp_rce::install']
    -> Class['wingftp_rce::config']
    -> Class['wingftp_rce::service']
}