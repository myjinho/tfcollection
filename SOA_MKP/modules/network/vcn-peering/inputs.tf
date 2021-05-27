/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */
variable "tenancy_ocid" {
}

variable "service_name_prefix" {
}

variable "region" {
}

variable "wls_availability_domain" {
}

variable "compartment_ocid" {
}

variable "instance_shape" {
}

variable "ssh_public_key" {
}

// This is WLS VCN name, if provided.
variable "wls_vcn_name" {
}

/*
 This is existing VCN OCID.
 If both vcn_name and existing_vcn_id are provided, vcn_name is for creating new WLS VCN and existing_vcn_id is OCIDB VCN.
 In non-JRF or ATP DB case, only one of vcn_name or existing_vcn_id should be provided. If both are provided, vcn_name will
 have precedence.
*/
variable "existing_vcn_id" {
}

// OCID of the new VCN created for WLS.
variable "wls_vcn_id" {
}

variable "wls_vcn_cidr" {
}

variable "wls_dns_subnet_cidr" {
}

variable "wls_internet_gateway_id" {
  type = list(string)
}

// OCI DB params for VCN peering
variable "ocidb_compartment_id" {
}

variable "ocidb_dbsystem_id" {
}

variable "ocidb_database_id" {
}

variable "ocidb_vcn_cidr" {
}

//variable "ocidb_vcn_compartment_id" {}
//variable "ocidb_availability_domain" {}
variable "ocidb_dns_subnet_cidr" {
}

//variable "ocidb_subnet_id" {}

/*
* Using https://docs.cloud.oracle.com/iaas/images/image/66379f54-edd0-4294-895f-47291a3eb4ed/
* Oracle-provided image = Oracle-Linux-7.6-2019.02.20-0
*
* Also see https://docs.us-phoenix-1.oraclecloud.com/images/ to pick another image in future.
*/
variable "instance_image_ocid" {
  type = map(string)

  default = {
    us-phoenix-1   = "ocid1.image.oc1.phx.aaaaaaaacss7qgb6vhojblgcklnmcbchhei6wgqisqmdciu3l4spmroipghq"
    us-ashburn-1   = "ocid1.image.oc1.iad.aaaaaaaannaquxy7rrbrbngpaqp427mv426rlalgihxwdjrz3fr2iiaxah5a"
    eu-frankfurt-1 = "ocid1.image.oc1.eu-frankfurt-1.aaaaaaaa527xpybx2azyhcz2oyk6f4lsvokyujajo73zuxnnhcnp7p24pgva"
    uk-london-1    = "ocid1.image.oc1.uk-london-1.aaaaaaaarruepdlahln5fah4lvm7tsf4was3wdx75vfs6vljdke65imbqnhq"
    ca-toronto-1   = "ocid1.image.oc1.ca-toronto-1.aaaaaaaa7ac57wwwhputaufcbf633ojir6scqa4yv6iaqtn3u64wisqd3jjq"
  }
}

variable "bootStrapFile" {
  type    = string
  default = "./modules/network/vcn-peering/userdata/bootstrap"
}

// Private subnet support
variable "bastion_host" {
  default = ""
}

variable "bastion_host_private_key" {
  default = ""
}

variable "assign_public_ip" {
  default = "true"
}

variable "use_regional_subnet" {
}

variable "service_gateway_id" {
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

