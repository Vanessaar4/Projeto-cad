#!/usr/bin/env bash

check_psmdb()
{
# Waiting for Vault to boot
while ! mongo admin --port 27017 --eval "help" &> /dev/null; do
echo "=> Waiting for confirmation of PSMDB service startup" && sleep 2;
done
}

main()
{
check_psmdb

mongo admin --port 27017 <<EOF
db.createUser(
  {
    user: 'admin',
    pwd: 'admin',
    roles: ["userAdminAnyDatabase", "dbAdminAnyDatabase", "readWriteAnyDatabase"]
  });
EOF
}
chmod 600 /tmp/psmdb-tokenFile
main &

mongod -f /etc/mongod.conf