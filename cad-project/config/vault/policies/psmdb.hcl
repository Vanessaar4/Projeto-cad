path "database/creds/psmdb" {
  capabilities = ["read"]
}

path "secret/data/psmdb/*" {
  capabilities = ["create", "read"]
}
