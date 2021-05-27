/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */
# Gets a list of Availability Domains in the tenancy
data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

data "oci_identity_fault_domains" "wls_fault_domains" {
  #Required
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_ocid
}

data "template_file" "ad_names" {
  count    = length(data.oci_identity_availability_domains.ADs.availability_domains)
  template =  lookup(data.oci_identity_availability_domains.ADs.availability_domains[count.index], "name")
}

data "oci_core_subnet" "wls_subnet" {
  count = var.wls_subnet_id == "" ? 0 : 1

  #Required
  subnet_id = var.wls_subnet_id
}

locals {
  is_oci_db    = trimspace(var.ocidb_dbsystem_id) != "" ? true : false
  is_atp_db    = trimspace(var.atp_db_id) != "" ? true : false
  is_apply_JRF = local.is_oci_db || local.is_atp_db ? true : false
  num_fault_domains = length(
    data.oci_identity_fault_domains.wls_fault_domains.fault_domains,
  )
  #Availability Domains
  ad_names                    = compact(data.template_file.ad_names.*.rendered)
}

data "oci_database_db_systems" "ocidb_db_systems" {
  count = local.is_oci_db?1:0

  #Required
  compartment_id = var.ocidb_compartment_id

  filter {
    name   = "id"
    values = [var.ocidb_dbsystem_id]
  }
}

data "oci_database_database" "ocidb_database" {
  count = local.is_oci_db?1:0

  #Required
  database_id = var.ocidb_database_id
}

data "oci_database_db_home" "ocidb_db_home" {
  count = local.is_oci_db?1:0

  #Required
  db_home_id = data.oci_database_database.ocidb_database[0].db_home_id
}

data "oci_database_autonomous_database" "atp_db" {
  count = local.is_atp_db?1:0

  #Required
  autonomous_database_id = var.atp_db_id
}

data "template_file" "key_script" {
  template = file("./modules/compute/instance/templates/keys.tpl")

  vars = {
    pubKey = var.opc_key["public_key_openssh"]
  }
}

