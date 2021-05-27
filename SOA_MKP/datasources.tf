/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */

data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
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

data "oci_core_subnet" "bastion_subnet" {
  count = var.bastion_subnet_id == "" ? 0 : 1

  #Required
  subnet_id = var.bastion_subnet_id
}

locals {
  // Only when both WLS VCN name is provided (vcn_name) and DB VCN ID is provided (existing_vcn_id)
  is_vcn_peering = var.wls_vcn_name != "" && var.existing_vcn_id != "" ? true : false
  num_ads = length(
    data.oci_identity_availability_domains.ADs.availability_domains,
  )
  is_single_ad_region = local.num_ads == 1 ? true : false
}

