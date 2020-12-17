#!/bin/sh

# Function to check if vault was initialized
check_vault()
{
    # Waiting for Vault to boot
		while ! nc -vz ${HOSTNAME} 8200 &> /dev/null; do
			echo "=> Waiting for confirmation of Vault service startup" && sleep 2;
		done
}

# Authenticating user with root access token
root_user_authentication()
{
    TOKEN=$(awk 'NR == 6{print $4}' /etc/vault/.keys)

    vault login ${TOKEN} &> /dev/null
    if [ $? != 0 ];then
        echo "Invalid root token. Token: ${TOKEN}"
        exit
    fi

    echo "Root user authenticate with success!"
}

# Function responsible to create the policies
# that will be used in token generations
generate_policies() {
	TIME="20s"
  # Loading every policies
  POLICIES_DIRECTORY="/etc/vault/policies/"
  POLICIES=$(ls ${POLICIES_DIRECTORY} | sed s/.hcl//g)

  for POLICY in ${POLICIES};do
    # Creating the policies that will be used in token generations
    # Each police is mapped with the name registered in file
    vault policy write ${POLICY} ${POLICIES_DIRECTORY}${POLICY}.hcl  > dev/null

    TOKEN=$(vault token create -policy="${POLICY}" \
      -renewable=false \
      -period=${TIME} \
      -display-name="${POLICY}" \
      -field="token")

    echo -e "\33[32m${POLICY} TOKEN: ${TOKEN}\33[0m"
  done
}

# Function to unseal vault
unseal()
{
    # Using the first three keys to unlock the vault
    KEYS=$(cat /etc/vault/.keys)
    ID_KEY=$(( ( RANDOM % 5 )  + 1 ))
    USED_KEYS=0
    while [[ ${USED_KEYS} != 3 ]]
    do
        KEY=$(echo "${KEYS}" | awk NR==${ID_KEY}'{print $4}')

        vault operator unseal "${KEY}" &> /dev/null

        if [ $? != 0 ];then
            echo "Invalid key to unseal vault. Key: ${KEY}"
            exit
        fi

        KEYS=$(echo "${KEYS}" | sed "${ID_KEY}d")
        USED_KEYS=$(( ${USED_KEYS} + 1))
        ID_KEY=$(( ( RANDOM % (5 - USED_KEYS) )  + 1 ))
    done

    echo "Vault unseal with success!"
}

# Function responsible for setting up the
# Vault environment and controlling system startup
main()
{
    # Function to check if vault was initialized
    check_vault

    # Checking if the Vault has been previously started
    local INITIALIZED_BEFORE=$(vault status | grep "Initialized" | awk '{print $2}')

    # If It hasn't been previously started, only is necessary
    # to unseal Vault, revoke the leases
    # previously provided and generate new tokens
    if [[ $INITIALIZED_BEFORE == "false" ]]
    then
        echo "Not previously initialized"

        # Activating the vault and generating unlock keys and root token
        vault operator init -format="table" | grep -E "Unseal Key|Initial Root Token" > /etc/vault/.keys
    else
        echo "Previously initialized"
    fi

    # Function to unseal vault
    unseal

    # Authenticating user with root access token
    root_user_authentication

    # Enabling secrets enrollment in Vault
    vault secrets enable -version=2 -path=secret/ kv

    generate_policies > ~/infra_tokens


vault secrets enable database

vault write database/config/psmdb \
plugin_name=mongodb-database-plugin \
allowed_roles=psmdb \
connection_url="mongodb://{{username}}:{{password}}@psmdb:27017/admin" \
usename="admin" \
password="admin" \
verify_connection="false"

vault write database/roles/psmdb \
db_name=psmdb \
Creation_statements='{"db": "admin", "roles": [{"role": "readwrite"}] }' \
revocation_statements='{"db": "admin"}' \
default_ttl="1h" \
max_ttl="24"

vault secrets enable rabbitmq

vault write rabbitmq/roles/my-role \
vhosts='{"/":{"write": ".*", "read": ".*"}}'

}

main &

# Starting Vault with its configurations
vault server -config=/etc/vault/config.hcl
