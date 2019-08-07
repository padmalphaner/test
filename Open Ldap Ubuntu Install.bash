apt-get update
apt-get install slapd ldap-utils migrationtools -y
# enter admin passwd when prompted

## to reconfigure openldap details
sudo dpkg-reconfigure slapd
    Omit OpenLDAP server configuration? No
    DNS domain name? dyhwin.com
    Organization name? dywhin
    Administrator password? Bluered7  (BlueOrange25@)
    Database backend? MDB
    Remove the database when slapd is purged? No
    Move old database? Yes
    Allow LDAPv2 protocol? No

sudo ufw enable
sudo ufw allow 389
sudo ufw allow ssh
sudo ufw reload

slappasswd
{SSHA}O3Qu9NfbI9JzY7YeCbV6XaGnlRa4gxAu

### configure ldap
cd /etc/ldap/slapd.d/cn=config
vi olcDatabase={1}mdb.ldif  ## edit following lines
olcAccess: {0}to attrs=userPassword by self write by dn.base="cn=admin,dc=dywhin,dc=com" write by anonymous auth by * none
olcAccess: {1}to * by dn.base="cn=admin,dc=dywhin,dc=com" write by self write by * read

vi olcDatabase={-1}frontend.ldif
olcAccess: {0}to attrs=userPassword by self write by dn.base="cn=admin,dc=dywhin,dc=com" write by anonymous auth by * none
olcAccess: {1}to * by dn.base="cn=admin,dc=dywhin,dc=com" write by self write by * read

vi olcDatabase={0}config.ldif
olcAccess: {0}to * by dn.base="gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth" read by dn.base="cn=admin,dc=dywhin,dc=com" read by * none

### configure migrationtools
cd /usr/share/migrationtools
copy "migrate_common.ph" file into this location
edit "migrate_passwd.pl" and "migrate_group.pl" files to correct the "migrate_common.ph" path

## verify the configuration files
slaptest -u

systemctl enable slapd
service slapd restart

## verify ldap search
ldapsearch -x -b "dc=dywhin,dc=com"

## Adding an organizational unit (OU)
vi ou.ldif

dn: ou=users,dc=dywhin,dc=com
objectClass: organizationalUnit
objectClass: top
ou: users

dn: ou=groups,dc=dywhin,dc=com
objectClass: organizationalUnit
ou: groups

## add dn: users and groups
ldapadd -D cn=admin,dc=dywhin,dc=com -w Bluered7 -f ou.ldif

#### adding ldap user and group
adduser dive_info --gecos "dive_info dive_info" --disabled-password
echo -e "dive4275@\ndive4275@" | passwd dive_info
echo -e "Dive@4275!\nDive@4275!" | passwd dive_info

cd /usr/share/migrationtools/

cat /etc/passwd | grep dive_info > dive_info
cat /etc/group | grep dive_info > dive_info.group

./migrate_passwd.pl dive_info dive_info.ldif
./migrate_group.pl dive_info.group dive_info_group.ldif

ldapadd -D "cn=admin,dc=dywhin,dc=com" -x -w BlueOrange25@ -f dive_info.ldif
ldapadd -D "cn=admin,dc=dywhin,dc=com" -x -w BlueOrange25@ -f dive_groups.ldif

ldappasswd -x -D cn=admin,dc=dywhin,dc=com -w BlueOrange25@ -s Dive@4275! "uid=dive_info,ou=users,dc=dywhin,dc=com"
ldappasswd -x -D cn=admin,dc=dywhin,dc=com -w BlueOrange25@ -s test1 "uid=test1,ou=users,dc=dywhin,dc=com"
ldappasswd -x -D cn=admin,dc=dywhin,dc=com -w BlueOrange25@ -s Dive@4275! "uid=dive_info,ou=users,dc=dywhin,dc=com"

## delete ldap users
ldapdelete -D cn=admin,dc=dywhin,dc=com -w Bluered7 "uid=anand,ou=users,dc=dywhin,dc=com"
## change user password
ldappasswd -x -D cn=admin,dc=dywhin,dc=com -w Bluered7 -S "uid=dive,ou=users,dc=dywhin,dc=com"

## NFS setup
apt-get -y install nfs-kernel-server rpcbind

vi /etc/exports
   /home 45.79.204.117(rw)
   /home       *(rw,sync,no_root_squash,no_subtree_check)

service rpcbind restart
service nfs-server restart

showmount -e ldap


dn: dc=dywhin,dc=com
objectclass: top
objectclass: domain
objectclass: extensibleObject
dc: memorynotfound

dn: ou=groups,dc=memorynotfound,dc=com
objectclass: top
objectclass: organizationalUnit
ou: groups

dn: ou=people,dc=memorynotfound,dc=com
objectclass: top
objectclass: organizationalUnit
ou: people


dn: uid=john,ou=people,dc=memorynotfound,dc=com
objectclass: top
objectclass: person
objectclass: organizationalPerson
objectclass: inetOrgPerson
cn: John Doe
uid: john
userPassword: {SHA}5en6G6MezRroT3XKqkdPOmY/BfQ=


dn: cn=developers,ou=groups,dc=memorynotfound,dc=com
objectclass: top
objectclass: groupOfUniqueNames
cn: developers
ou: developer
uniqueMember: uid=john,ou=people,dc=memorynotfound,dc=com

dn: cn=managers,ou=groups,dc=memorynotfound,dc=com
objectclass: top
objectclass: groupOfUniqueNames
cn: managers
ou: manager
uniqueMember: uid=john,ou=people,dc=memorynotfound,dc=com




ldapadd -D "cn=admin,dc=dywhin,dc=com" -x -w BlueOrange25@ -f dive_admin.ldif
ldapadd -D "cn=admin,dc=dywhin,dc=com" -x -w BlueOrange25@ -f dive_user.ldif


ldappasswd -x -D cn=admin,dc=dywhin,dc=com -w BlueOrange25@ -s dive@4275! "uid=dive_user,ou=users,dc=dywhin,dc=com"


ldapdelete -D cn=admin,dc=dywhin,dc=com -w BlueOrange25@ "uid=padma,ou=users,dc=dywhin,dc=com"

ldapdelete -D cn=admin,dc=dywhin,dc=com -w BlueOrange25@ "cn=DIVEMANAGER_USER,ou=groups,dc=dywhin,dc=com"
ldapdelete -D cn=admin,dc=dywhin,dc=com -w BlueOrange25@ "cn=DIVEMANAGER_ADMIN,ou=groups,dc=dywhin,dc=com"

ldapadd -D "cn=admin,dc=dywhin,dc=com" -x -w BlueOrange25@ -f divemanager_admin.ldif
ldappasswd -x -D cn=admin,dc=dywhin,dc=com -w BlueOrange25@ -s dive@4275! "uid=divemanager_admin,ou=users,dc=dywhin,dc=com"





dn: cn=DIVEMANAGER_USER,ou=groups,dc=dywhin,dc=com
objectClass: groupOfUniqueNames
description: divemanager_user
cn: DIVEMANAGER_USER
uniqueMember: uid=dive_user,ou=users,dc=dywhin,dc=com


dn: cn=DIVEMANAGER_ADMIN,ou=groups,dc=dywhin,dc=com
objectClass: groupOfUniqueNames
description: divemanager_admin
cn: DIVEMANAGER_ADMIN
uniqueMember: uid=dive_admin,ou=users,dc=dywhin,dc=com


ldapdelete -D cn=admin,dc=dywhin,dc=com -w Bluered7 "cn=DIVEMANAGER_ADMIN,ou=groups,dc=dywhin,dc=com




# dive_admin, users, dywhin.com
dn: uid=dive_admin,ou=users,dc=dywhin,dc=com
objectClass: shadowAccount
objectClass: top
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
cn: DIVEMANAGER_ADMIN
gidNumber: 1034
homeDirectory: /home/dive_admin
sn: dive_admin
uid: dive_admin
uidNumber: 1033
gecos: dive_admin,,,
loginShell: /bin/bash
mail: dive_admin@dywhin.com
shadowLastChange: 17794
shadowMax: 99999
shadowWarning: 6



# dive_user, users, dywhin.com
dn: uid=dive_user,ou=users,dc=dywhin,dc=com
objectClass: shadowAccount
objectClass: top
objectClass: posixAccount
objectClass: inetOrgPerson
objectClass: organizationalPerson
objectClass: person
cn: DIVEMANAGER_USER
gidNumber: 1035
homeDirectory: /home/dive_user
sn: dive_user
uid: dive_user
uidNumber: 1033
gecos: dive_user,,,
loginShell: /bin/bash
mail: dive_user@dywhin.com
shadowLastChange: 17792
shadowMax: 99999
shadowWarning: 4

ldapadd -D "cn=admin,dc=dywhin,dc=com" -x -w BlueOrange25@ -f dive_admin.ldif
ldappasswd -x -D cn=admin,dc=dywhin,dc=com -w BlueOrange25@ -s dive@4275! "uid=dive_admin,ou=users,dc=dywhin,dc=com"




ldapadd -D "cn=admin,dc=dywhin,dc=com" -x -w BlueOrange25@ -f divemanager_user.ldif
ldappasswd -x -D cn=admin,dc=dywhin,dc=com -w BlueOrange25@ -s dive@4275! "uid=divemanager_admin,ou=users,dc=dywhin,dc=com"
