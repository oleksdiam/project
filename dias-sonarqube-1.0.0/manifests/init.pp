# == Class: sonarqube
#
class sonarqube (

  $version          = '6.7.1',
  $user             = 'sonar',
  $group            = 'sonar',
  $user_system      = true,
  $service          = 'sonar',
  $installroot      = '/usr/local',
  $home             = undef,
  $host             = undef,
  $port             = 9000,
  $portAjp          = -1,
  $download_url     = 'https://sonarsource.bintray.com/Distribution/sonarqube',
  $download_dir     = '/usr/local/src',
  $context_path     = '/',
  $arch             = $sonarqube::paras::arch,
  $https            = {},
  $ldap             = {},
  # acceptable values of <db_type> are 'embedded' , 'mysql' , 'psql' , 'oracle'
  $db_provider      = 'embedded',
  $db_host          = 'localhost',

  # ldap and pam are mutually exclusive. Setting $ldap will annihilate the setting of $pam
  $pam              = {},
  $crowd            = {},
  $jdbc             = {
    url                               => "jdbc:h2:tcp://localhost:9092/sonar",
    username                          => 'sonar',
    password                          => 'sonar',
    max_active                        => '50',
    max_idle                          => '5',
    min_idle                          => '2',
    max_wait                          => '5000',
    min_evictable_idle_time_millis    => '600000',
    time_between_eviction_runs_millis => '30000',
  },
  $log_folder       = '/var/local/sonar/logs',
  $updatecenter     = true,
  $http_proxy       = {},
  $profile          = false,
  $web_java_opts    = undef,
  $search_java_opts = undef,
  $search_host      = '127.0.0.1',
  $search_port      = '9001',
  $config           = undef,
) inherits sonarqube::params {
  validate_absolute_path($download_dir)
  Exec {
    path => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin',
  }
  File {
    owner => $user,
    group => $group,
  }

  # wget from https://github.com/maestrodev/puppet-wget
  # include wget
  package { 'wget':
    ensure => 'installed',
  }

  $package_name = 'sonarqube'

  if $home != undef {
    $real_home = $home
  } else {
    $real_home = '/var/local/sonar'
  }
  Sonarqube::Move_to_home {
    home => $real_home,
  }

  $extensions_dir = "${real_home}/extensions"
  $plugin_dir = "${extensions_dir}/plugins"

  $installdir = "${installroot}/${service}"
  $tmpzip = "${download_dir}/${package_name}-${version}.zip"
  $script = "${installdir}/bin/${arch}/sonar.sh"
  $pid_d  = "${installdir}/bin/${arch}/./SonarQube.pid"

  if ! defined(Package[unzip]) {
    package { 'unzip':
      ensure => present,
      before => Exec[untar],
    }
  }

  user { $user:
    ensure     => present,
    home       => $real_home,
    managehome => false,
    system     => $user_system,
  }
  ->
  group { $group:
    ensure => present,
    system => $user_system,
  }
  ->
  wget::fetch { 'download-sonar':
    source      => "${download_url}/${package_name}-${version}.zip",
    destination => $tmpzip,
  }
  ->
  # ===== Create folder structure =====
  # so uncompressing new sonar versions at update time use the previous sonar home,
  # installing new extensions and plugins over the old ones, reusing the db,...

  # Sonar home
  file { $real_home:
    ensure => directory,
    mode   => '0740',
  }
  ->
  file { "${installroot}/${package_name}-${version}":
    ensure => directory,
  }
  ->
  file { $installdir:
    ensure => link,
    target => "${installroot}/${package_name}-${version}",
    notify => Service['sonarqube'],
  }
  ->
  sonarqube::move_to_home { 'data': }
  ->
  sonarqube::move_to_home { 'extras': }
  ->
  sonarqube::move_to_home { 'extensions': }
  ->
  sonarqube::move_to_home { 'logs': }
  ->
  # ===== Install SonarQube =====
  exec { 'untar':
    command => "unzip -o ${tmpzip} -d ${installroot} && chown -R ${user}:${group} ${installroot}/${package_name}-${version} && chown -R ${user}:${group} ${real_home}",
    creates => "${installroot}/${package_name}-${version}/bin",
    notify  => Service['sonarqube'],
  }
  # ->
  # file { $script:
  #   mode    => '0755',
  #   content => template('sonarqube/sonar.sh.erb'),
  # }
  ->
  file { "/etc/init.d/${service}":
    ensure => link,
    target => $script,
  }

  # Sonar configuration files
  if $config != undef {
    file { "${installdir}/conf/sonar.properties":
      source  => $config,
      require => Exec['untar'],
      notify  => Service['sonarqube'],
      mode    => '0664',
    }
  } else {
    file { "${installdir}/conf/sonar.properties":
      content => template('sonarqube/sonar.properties.erb'),
      require => Exec['untar'],
      notify  => Service['sonarqube'],
      mode    => '0664',
    }
  }

  file { "/etc/systemd/system/sonar.service":
    content => template('sonarqube/sonar.service.erb'),
    require => Exec['untar'],
    notify  => Service['sonarqube'],
    mode    => '0664',
  }

  file { "/etc/security/limits.conf":
    content => template('sonarqube/limits.conf.erb'),
    require => Exec['untar'],
    notify  => Service['sonarqube'],
    mode    => '0664',
  }

  file { "/etc/sysctl.conf":
    content => template('sonarqube/limits.conf.erb'),
    require => Exec['untar'],
    notify  => Service['sonarqube'],
    mode    => '0664',
  }


  file { '/tmp/cleanup-old-plugin-versions.sh':
    content => template("${module_name}/cleanup-old-plugin-versions.sh.erb"),
    mode    => '0755',
  }
  ->
  file { '/tmp/cleanup-old-sonarqube-versions.sh':
    content => template("${module_name}/cleanup-old-sonarqube-versions.sh.erb"),
    mode    => '0755',
  }
  ->
  exec { 'remove-old-versions-of-sonarqube':
    command     => "/tmp/cleanup-old-sonarqube-versions.sh ${installroot} ${version}",
    path        => '/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/bin',
    refreshonly => true,
    subscribe   => File["${installroot}/${package_name}-${version}"],
  }

  # The plugins directory. Useful to later reference it from the plugin definition
  file { $plugin_dir:
    ensure => directory,
  }

  case $facts['kernel'] {
    'Linux' : {
      case $facts['os']['family'] {
        'RedHat', 'Amazon' : {
          # Oracle Java 6 comes in a special rpmbin format
          if $operatingsystemmajrelease == '6' {
            exec { 'iptables':
              command => "iptables -I INPUT 1 -p tcp -m multiport --ports ${port} -m comment --comment 'Custom HTTP Web Host' -j ACCEPT && iptables-save > /etc/sysconfig/iptables",
              path => "/sbin",
              refreshonly => true,
              subscribe => Exec['untar'],
            }
            service { 'iptables':
              ensure => running,
              enable => true,
              hasrestart => true,
              subscribe => Exec['iptables'],
            }
          }
          elsif $operatingsystemmajrelease == '7' {
            exec { 'firewall-cmd':
              command => "firewall-cmd --zone=public --add-port=${port}/tcp --permanent",
              path => "/usr/bin/",
              refreshonly => true,
              subscribe => Exec['untar'],
            }
            service { 'firewalld':
              ensure => running,
              enable => true,
              hasrestart => true,
              subscribe => Exec['firewall-cmd'],
            }
          }
        }
        # 'Debian' : {
        # }
        default : {
          fail ("unsupported platform ${$facts['os']['name']}") }
      }

    }
    default : {
      fail ( "unsupported platform ${$facts['kernel']}" ) }
  } 

  service { 'sonarqube':
    ensure     => running,
    name       => $service,
    hasrestart => true,
    hasstatus  => true,
    enable     => true,
    require    => File["/etc/init.d/${service}"],
  }
}
