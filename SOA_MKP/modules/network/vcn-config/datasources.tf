/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */
data "oci_core_vcns" "tf_vcns" {
  #Required
  compartment_id = var.compartment_id

  #Optional
  filter {
    name   = "id"
    values = [var.vcn_id]
  }
}

data "oci_core_internet_gateways" "tf_internet_gateways" {
  #Required
  compartment_id = var.compartment_id
  vcn_id         = var.existing_vcn_id == "" ? var.vcn_id : var.existing_vcn_id
}

data "oci_core_nat_gateways" "tf_nat_gateways" {
  #Required
  compartment_id = var.compartment_id

  #Optional
  vcn_id = var.existing_vcn_id == "" ? var.vcn_id : var.existing_vcn_id
}

locals {
  num_nat_gws   = length(data.oci_core_nat_gateways.tf_nat_gateways.nat_gateways)
  nat_gw_exists = local.num_nat_gws == 0 ? false : true
}

data "oci_core_service_gateways" "tf_service_gateways" {
  #Required
  compartment_id = var.compartment_id

  #Optional
  vcn_id = var.existing_vcn_id == "" ? var.vcn_id : var.existing_vcn_id
}

data "oci_core_services" "tf_services" {
}

