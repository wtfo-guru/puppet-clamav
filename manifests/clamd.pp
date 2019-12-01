# clamd.pp
# Set up clamd config and service.
#

class clamav::clamd {

  $config_options = $clamav::_clamd_options
  $db_directory = $clamav::params::clamd_default_databasedirectory

  # NOTE: In RedHat and Archlinux this is part of the base clamav_package
  if $clamav::clamd_package {
    package { 'clamd':
      ensure => $clamav::clamd_version,
      name   => $clamav::clamd_package,
      before => File['clamd.conf'],
    }
    $service_subscribe = [
      File['clamd.conf'],
      Package['clamd'],
    ]
  }
  else {
    $service_subscribe = File['clamd.conf']
  }

  case $facts['os']['family'] {
    'RedHat': {
      if $facts['operatingsystemmajrelease'] =~ /^7/ {
        # solve this chicken/egg problem, clamd can't start until database files are preset
        # for redhat 7 those are in the clamav-data packages, which apparently isn't required by any other package
        # files would be obtained from the first freshclam run which might be 3 hours after first install
        ensure_packages(['clamav-data'], {'ensure' => 'installed', 'before' => Service['clamd']})
      }
    }
    'Debian': {
      # clamav-daemon not start the service without this file, I think it used
      # to be provided by freshclam, but not sure
      file {"${db_directory}/daily.inc":
        ensure => file,
        mode   => '0644',
        owner  => $clamav::user,
        group  => $clamav::group,
        before => Service['clamd'],
      }
    }
    default: {}
  }

  file { 'clamd.conf':
    ensure  => file,
    path    => $clamav::clamd_config,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template("${module_name}/clamav.conf.erb"),
  }

  service { 'clamd':
    ensure     => $clamav::clamd_service_ensure,
    name       => $clamav::clamd_service,
    enable     => $clamav::clamd_service_enable,
    hasrestart => true,
    hasstatus  => true,
    subscribe  => $service_subscribe,
  }
}
