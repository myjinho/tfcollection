output "OPCPrivateKey" {
  value = {
    "public_key_openssh" = tls_private_key.opc_key.public_key_openssh
    "private_key_pem"    = tls_private_key.opc_key.private_key_pem
  }
}

output "OraclePrivateKey" {
  value = {
    "public_key_openssh" = tls_private_key.oracle_key.public_key_openssh
    "private_key_pem"    = tls_private_key.oracle_key.private_key_pem
  }
}

