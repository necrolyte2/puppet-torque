require 'spec_helper'

describe 'torque::server' do

  let(:facts) {{
    :operatingsystem => 'Debian',
    :osfamily        => 'Debian',
    :lsbdistcodename => 'wheezy',
    :lsbdistid       => 'Debian',
    :hostname        => 'foo.bar',
    :concat_basedir  => '/var/lib/puppet/concat',
  }}

  include_context 'hieradata'

  it { should compile.with_all_deps }
  it { should contain_class('torque::server') }
  it { should contain_class('torque::server::config') }
  it { should contain_class('torque::maui') }
  it { should_not contain_class('torque::munge') }

  it { should contain_package('torque-server') }
  it { should contain_service('torque-server').with(
        :ensure => 'running',
        :enable => true
  )}

  it {
    should contain_file(
      '/etc/torque/server_name'
    ).with({
    'ensure'  => 'present',
    'owner'   => 'root',
    'group'   => 'root',
    'mode'    => '0644',
    }).with_content(/foo.bar/)
  }

  it {
    should contain_file(
      '/var/spool/torque/qmgr_config'
    ).with({
    'ensure'  => 'present',
    'owner'   => 'root',
    'group'   => 'root',
    'mode'    => '0600',
    }).with_content(/# server commands/)
  }
end