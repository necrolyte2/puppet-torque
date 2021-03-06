class torque::auth (
    $auth_allowed_users = $torque::params::auth_allowed_users,
    $version            = $torque::params::version,
    $build              = $torque::params::build,
    $build_dir          = $torque::params::build_dir
) inherits torque::params {
    include selinux

    # Allows sshd to read ${torque_home}/mom_priv/jobs/*
    # as that is how the pam_pbssimpleauth.so determins if a user
    # has a job running or not
    selinux::module { 'torque':
        source => 'puppet:///modules/torque/selinux'
    }

    $full_build_dir = "${build_dir}/torque-${version}"
    exec {"install_torque_pam_${version}":
        command => "${full_build_dir}/torque-package-pam-linux-x86_64.sh --install",
        require => Exec["make_packages_${version}"],
        creates => "/lib64/security/pam_pbssimpleauth.so"
    }
    # Put pam_access.so after last account line
    # but before any includes
    augeas {"/etc/pam.d/sshd/pam_access.so":
        context     => "/files/etc/pam.d/sshd",
        changes     => [
            "ins 100 before *[type='account'][control='include'][last()]",
            "set 100/type account",
            "set 100/control required",
            "set 100/module pam_access.so"
        ],
        onlyif => "match *[type='account' and module='pam_access.so'] size == 0"
    }
    # Insert pam_pbssimpleauth.so just before pam_access.so
    augeas {"/etc/pam.d/sshd/pam_pbssimpleauth.so":
        context     => "/files/etc/pam.d/sshd",
        changes     => [
            "ins 101 before *[type='account' and module='pam_access.so']",
            "set 101/type account",
            "set 101/control sufficient",
            "set 101/module pam_pbssimpleauth.so"
        ],
        onlyif => "match *[module='pam_pbssimpleauth.so'] size == 0",
        require => [
            Exec["install_torque_pam_${version}"],
            Augeas['/etc/pam.d/sshd/pam_access.so'],
            Exec["install_torque_mom_${version}"]
        ]
    }
    # Add access line to end if no other access rules
    # Build a augeas change set for all auth_allowed_users
    $except_users = $auth_allowed_users.reduce([]) | $memo, $entry | {
        $memo + ["set access[last()]/except/user[last()+1] ${entry}"]
    }
    augeas {"/etc/security/access.conf":
        context     => "/files/etc/security/access.conf",
        changes     => [
            "set access[last()] -",
            "set access[last()]/user[last()+1] ALL",
            "ins except after access[last()]/user",
            "set access[last()]/origin ALL",
        ] + $except_users,
        onlyif      => "match access[.='-' and user='ALL' and origin='ALL'] size == 0"
    }
    # Ensure except user list is always correct
    $except_users_replace = $auth_allowed_users.reduce([]) | $memo, $entry | {
        $memo + ["set access[.='-' and user='ALL' and origin='ALL']/except/user[last()+1] ${entry}"]
    }
    augeas {"/etc/security/access.conf_set_users":
        context     => "/files/etc/security/access.conf",
        changes     => [
            'defvar p access[.="-" and user="ALL" and origin="ALL"]',
            'rm $p/except',
            'ins except after $p/user',
        ] + $except_users_replace,
        onlyif      => "match access[.='-' and user='ALL' and origin='ALL'] size != 0"
    }
}
