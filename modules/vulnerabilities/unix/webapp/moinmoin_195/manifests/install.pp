class moinmoin_195::install {
  $buster_repo = "deb http://172.33.0.44/deb.debian.org/debian buster main contrib non-free\n"

  Exec { path => ['/bin', '/usr/bin', '/usr/local/bin', '/sbin', '/usr/sbin'] }

  file { '/etc/apt/sources.list.d/buster.list':
    ensure  => file,
    content => $buster_repo,
  }
  -> exec { 'apt-update-buster':
    command => 'apt-get update',
  }
  -> exec { 'install-python2-packages':
    command => 'apt-get install -y --allow-downgrades python2 python2-dev python-setuptools libapache2-mod-wsgi',
  }
  -> file { '/usr/local/src/MoinMoin-1.9.5.tar.gz':
    ensure => file,
    source => 'puppet:///modules/moinmoin_195/MoinMoin-1.9.5.tar.gz',
  }
  -> exec { 'unzip-moinmoin':
    command => '/bin/tar -xzf /usr/local/src/MoinMoin-1.9.5.tar.gz',
    cwd     => '/usr/local/src',
    creates => '/usr/local/src/moin-1.9.5/',
  }
  -> exec { 'install-moinmoin':
    command => '/usr/bin/python2 setup.py install --force --prefix=/usr/local --record=install.log',
    cwd     => '/usr/local/src/moin-1.9.5',
  }
  -> exec { 'cleanup':
    command => '/bin/rm /usr/local/src/* -rf',
  }
}