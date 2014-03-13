class torque::client(
  $torque_server,
  $mom_ensure         = 'installed',
  $package_ensure     = 'installed',
  $mom_service_name   = 'torque-mom',
  $mom_service_enable = true,
  $mom_service_ensure = 'running',
  $enable_munge       = false,
  ) inherits torque {

  # command line interface to Torque server
  package { 'torque-client':
    ensure => $package_ensure,
  }

  class { 'torque::mom':
    torque_server      => $torque_server,
    mom_ensure         => $mom_ensure,
    mom_service_name   => $mom_service_name,
    mom_service_enable => $mom_service_enable,
    mom_service_ensure => $mom_service_ensure,
  }

  if($enable_munge) {
    class { 'torque::munge': }
  }
}
