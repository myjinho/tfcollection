/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */
variable "ssh_private_key" {
  type = string
}

variable "host_ips" {
  type = list(string)
}

variable "admin_ip" {
}

variable "numVMInstances" {
}

variable "is_atp_db" {
  default = "false"
}

variable "atp_db_id" {
  default = ""
}

variable "atp_db_name" {
  default = ""
}

variable "mode" {
}

variable "atp_db_wallet_password" {
}

variable "db_password" {
  default = ""
}

variable "rcu_schema_password" {
}

variable "wls_admin_password" {
  type = string
}

variable "wls_nm_password" {
  type = string
}

variable "creds_path" {
  default = "/opt/.creds"
}

variable "volumeAttachmentInfo" {
  type = list(string)
}

variable "bastion_host" {
  default = ""
}

variable "bastion_host_private_key" {
  default = ""
}

variable "assign_public_ip" {
  default = "true"
}

variable "oracle_key" {
  type = map(string)
}

variable "kms_service_endpoint" {
}

variable "kms_key_id" {
}

variable "use_kms_decryption" {
  default = "true"
}

variable "instance_ids" {
  type = list(string)
}

variable "add_load_balancer" {
}

variable "lb_public_ip" {
  type = list(string)
}

variable "lbip_filepath" {
  default = "/tmp/lb_public_ip.txt"
}

variable "idcs_client_secret" {
}

