/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */

locals {
  dns_label = "subnet${var.service_name_prefix}"

  // Only when both WLS VCN name is provided (vcn_name) and DB VCN ID is provided (existing_vcn_id)
  // and the WLS VCN and OCI DB VCN is not same then we know it is peered VCN case.
  is_vcn_peering = var.wls_vcn_name != "" && var.existing_vcn_id != "" && var.ocidb_dbsystem_id != "" ? true : false
}

data "oci_core_vcns" "wls_vcn" {
  count = local.is_vcn_peering?1:0

  #Required
  compartment_id = var.compartment_ocid

  #Optional
  filter {
    name   = "id"
    values = [var.wls_vcn_id]
  }
}

data "oci_database_db_systems" "ocidb_db_systems" {
  count = local.is_vcn_peering?1:0

  #Required
  compartment_id = var.ocidb_compartment_id

  filter {
    name   = "id"
    values = [var.ocidb_dbsystem_id]
  }
}

data "oci_database_database" "ocidb_database" {
  count = local.is_vcn_peering?1:0

  #Required
  database_id = var.ocidb_database_id
}

data "oci_core_vcns" "ocidb_vcn" {
  count = local.is_vcn_peering?1:0

  #Required
  compartment_id = data.oci_database_db_systems.ocidb_db_systems.0.db_systems[0]["compartment_id"]

  #Optional
  filter {
    name   = "id"
    values = [var.existing_vcn_id]
  }
}

data "oci_core_internet_gateways" "ocidb_vcn_internet_gateway" {
  count = local.is_vcn_peering?1:0

  #Required
  compartment_id = data.oci_database_db_systems.ocidb_db_systems.0.db_systems[0]["compartment_id"]
  vcn_id         = var.existing_vcn_id
}

data "oci_core_subnet" "ocidb_subnet" {
  count = local.is_vcn_peering?1:0

  #Required
  subnet_id = data.oci_database_db_systems.ocidb_db_systems.0.db_systems[0]["subnet_id"]
}

data "oci_core_internet_gateways" "wls_vcn_internet_gateway" {
  count = local.is_vcn_peering?1:0

  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = var.wls_vcn_id
}

data "oci_identity_availability_domains" "ADs" {
  count          = local.is_vcn_peering?1:0
  compartment_id = var.tenancy_ocid
}

data "oci_core_services" "tf_services" {
}

