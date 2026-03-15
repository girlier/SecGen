class wingftp_rce::install {
  $secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $user = $secgen_parameters['unix_username'][0]
  $tarball = 'wftpserver-linux-64bit-7.4.3.tar.gz'
  
  # Generate a random domain name
  $domain_name = "ftp_${::fqdn_rand(10000, 'wingftp_domain')}"

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

  # Extract to /opt - tarball already contains wftpserver/ directory
  exec { 'extract-wingftp':
    cwd     => '/opt',
    command => "tar -xzf /tmp/${tarball}",
    creates => '/opt/wftpserver/wftpserver',
    require => [File['/opt/wftpserver'], File["/tmp/${tarball}"]],
  }

  # Run setup.sh to initialize data files (requires expect for automated input)
  package { 'expect':
    ensure => installed,
  }

  # Setup.sh asks for: admin name, admin password (8+ chars), listener port
  # Note: password123 + "WingFTP" suffix = password123WingFTP (8+ chars required)
  exec { 'setup-wingftp':
    cwd       => '/opt/wftpserver',
    command   => '/usr/bin/expect -c "spawn ./setup.sh; expect \"administrator name\"; send \"admin\r\"; expect \"administrator password\"; send \"password123\r\"; expect \"listener port\"; send \"5466\r\"; expect eof"',
    creates   => '/opt/wftpserver/Data/_ADMINISTRATOR',
    require   => [Exec['extract-wingftp'], Package['expect']],
    logoutput => true,
  }

  # Create domain setup script
  file { '/opt/wftpserver/create_domain.sh':
    ensure  => file,
    source  => 'puppet:///modules/wingftp_rce/create_domain.sh',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    require => Exec['setup-wingftp'],
  }

  # Create a systemd service to set up the domain after Wing FTP starts
  file { '/etc/systemd/system/wingftp-domain-setup.service':
    ensure  => file,
    content => "[Unit]
Description=Wing FTP Domain Setup
After=network.target wftpserver.service
Requires=wftpserver.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 5
ExecStart=/opt/wftpserver/create_domain.sh ${domain_name} /home/${user} admin password123WingFTP
RemainAfterExit=yes
TimeoutStartSec=60

[Install]
WantedBy=multi-user.target
",
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [Exec['setup-wingftp'], File['/opt/wftpserver/create_domain.sh']],
  }

  # Enable the domain setup service
  exec { 'enable-wingftp-domain-setup':
    command => 'systemctl daemon-reload && systemctl enable wingftp-domain-setup.service',
    require => File['/etc/systemd/system/wingftp-domain-setup.service'],
  }

  exec { 'cleanup-wingftp-tarball':
    command => "/bin/rm /tmp/${tarball}",
    onlyif  => "/bin/test -f /tmp/${tarball}",
  }
}