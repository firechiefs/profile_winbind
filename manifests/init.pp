# setups winbind on RedHat osfamily

# HIERA DATA:
#profile::winbind::config:
  # authconfig_update_cmd:
  #   authconfig command to update local host winbind and directory settings
  # package_ensure:
  #   genebean-winbind forge module will default to 'latest' for packages
  #   setting to present to disable constant upgrading
  #   packages manged by module are: 'samba-winbind-clients' & 'oddjob-mkhomedir
  # smb_workgroup:
  #   This is the short name of your domain (all upercase)
  # smb_realm:
  #   This is the long name of your domain (all upsercase)
  # domainadminuser:
  #   user account with rights to add computers to domain
  # domainadminpw:
  #   enrcypted password for account
  # pam_require_membership_of:
  #   Array of SIDs to group which are allowed to login locally
  #   SIDs can be determined by running 'wbinfo -n <group_name>'

# HIERA EXAMPLE:
# profile::winbind::config:
#   authconfig_update_cmd: 'authconfig --enablemkhomedir --enablewinbind
#                          --enablewinbindauth --update'
#   package_ensure: 'present'
#   smb_workgroup: 'FOO'
#   smb_realm: 'FOO.LOCAL'
#   domainadminuser: 'WINDOWS_USER'
#   domainadminpw: >
#     ENC[PKCS7,BQAEggEAK+D7IdbID+lMTrDBNKAOabJt7dajLVDaaHF1+7GuhbyxU0QF6AS+38+v
#     z9f0SJlKLP4gs/lIT88NYvfkxo4mN4t44NPSsrxJIRe9sKCtfnXG4WUTA8BgFxcgBAJ2LhfLo]
#   pam_require_membership_of:
#     - 'S-1-8-32-111111111-1111111111-11111111-1111' # WINDOWS_GROUP

class profile_winbind {
  # lookup winbind configuration hash
  $config = hiera_hash('profile::winbind::config')
  # validate configuration hash
  validate_hash($config)
  # validate password is properly decrypted
  validate_decrypted_content($config[domainadminpw])

  # localhost is not a valid hostname in Active Directory
  # unfortunately this is not handled in AD. Let's check for this
  if($::hostname !~ /localhost/) {
    # use forge class to create smb.conf and pam_winbind.con
    class { 'winbind':
      pam_require_membership_of => $config[pam_require_membership_of],
      smb_workgroup             => $config[smb_workgroup],
      smb_realm                 => $config[smb_realm],
      package_ensure            => $config[package_ensure],
    }

    # forge module does not join to AD. we'll have to join to AD
    # only run the exec if we're not already joined:
    #   '/usr/bin/wbinfo --own-domain | grep -v ${config[smb_workgroup]}'
    #     grep returns: 0 if joined (no match)
    #     grep returns: 1 if not joined (match)
    exec { 'add-to-domain':
      command =>
"/usr/bin/net ads join -U ${config[domainadminuser]}%${config[domainadminpw]}",
      onlyif  =>
        "/usr/bin/wbinfo --own-domain | grep -v ${config[smb_workgroup]}",
      path    => '/bin:/usr/bin',
      notify  => Service['winbind'],
    }

    # we need to determine if authconfig needs to be run
    # to do so we'll use linux 'test' command. it compares output of 2 commands
    #   returns 0: if commands return different values
    #   returns 1: if commands return same values
    $authconfig_exec_check_cmd  = "/usr/bin/test \
    \"`${config[authconfig_update_cmd]} --test`\" = \"`authconfig --test`\""

    # authconfig is used to configure winbind login as well as home direcotries
    # will only run if existing autoconfig settings differ from the ones in
    # heira
    exec {'authconfig command':
      path    => ['/usr/bin', '/usr/sbin'],
      command => $config[authconfig_update_cmd],
      unless  => $authconfig_exec_check_cmd,
    }

  } # end of if
  else {
    fail("FAIL: PROFILE::WINBIND hostname should be changed from default \
    ${::hostname} !!!")
  } # end of if/else

  # let's test if we're part of smb_workgroup
  validation_script { 'profile_winbind':
    profile_name    => 'profile_winbind',
    validation_data => $config[smb_workgroup],
  }

}
