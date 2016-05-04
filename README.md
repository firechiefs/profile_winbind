## PURPOSE:

Installs and configures winbind on RedHat Os Family

## HIERA DATA:
```
profile::winbind::config:
  authconfig_update_cmd:
    authconfig command to update local host winbind and directory settings
  package_ensure:
    genebean-winbind forge module will default to 'latest' for packages
    setting to present to disable constant upgrading
    packages manged by module are: 'samba-winbind-clients' & 'oddjob-mkhomedir
  smb_workgroup:
    This is the short name of your domain (all upercase)
  smb_realm:
    This is the long name of your domain (all upsercase)
  domainadminuser:
    user account with rights to add computers to domain
  domainadminpw:
    enrcypted password for account
  pam_require_membership_of:
    Array of SIDs to group which are allowed to login locally
    SIDs can be determined by running 'wbinfo -n <group_name>'
```
## HIERA EXAMPLE:
```
profile::winbind::config:
  authconfig_update_cmd: 'authconfig --enablemkhomedir --enablewinbind --enablewinbindauth --update'
 package_ensure: 'present'
 smb_workgroup: 'FOO'
 smb_realm: 'FOO.LOCAL'
 domainadminuser: 'WINDOWS_USER'
 domainadminpw: >
   ENC[PKCS7,BQAEggEAK+D7IdbID+lMTrDBNKAOabJt7dajLVDaaHF1+7GuhbyxU0QF6AS+38+vT88NYvfkxo4mN4t44NPSsrxJIRe9sKCtfnXG4WUTA8BgFxcgBAJ2LhfLo]
   pam_require_membership_of:
     - 'S-1-8-32-111111111-1111111111-11111111-1111'

```

## MODULE DEPENDENCIES:
```
puppet module install genebean-winbind
```
## USAGE:

#### Puppetfile:
```
mod "genebean-winbind",             '1.0.0'

mod 'validation_script',
  :git => 'https://github.com/firechiefs/validation_script',
  :ref => '1.0.0'

mod 'profile_winbind',
  :git => 'https://github.com/firechiefs/profile_winbind',
  :ref => '1.0.0'
```
#### Manifests:
```
# RedHat family specific profiles
if ($::osfamily == 'RedHat') {
  class role::*rolename* {
    include profile_winbind
  }
}
```
