# clamd.pp
# Set up clamd config and service.
#

class clamav::clamd {

  $config_options = $clamav::_clamd_options

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

  if lookup('clamav::clamd_requires_daily_inc', Boolean, first, false) {
    # some systems will not start the service without this file
    file {"${clamav::params::clamd_default_databasedirectory}/daily.inc":
      ensure => file,
      mode   => '0644',
      owner  => $clamav::user,
      group  => $clamav::group,
    }
  }
}
