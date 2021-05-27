/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */
resource "oci_core_local_peering_gateway" "ocidb_local_peering_gateway" {
  count = local.is_vcn_peering?1:0

  #Required
  compartment_id = data.oci_database_db_systems.ocidb_db_systems.0.db_systems[0]["compartment_id"]
  vcn_id         = var.existing_vcn_id

  #Optional
  display_name  = "OCIDB_LPG"
  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

resource "oci_core_local_peering_gateway" "wls_local_peering_gateway" {
  count = local.is_vcn_peering?1:0

  #Required
  compartment_id = var.compartment_ocid
  vcn_id         = var.wls_vcn_id

  #Optional
  display_name = "WLS_LPG"

  #Peer WLS and OCI DB LPGs
  peer_id = oci_core_local_peering_gateway.ocidb_local_peering_gateway[0].id

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

resource "oci_core_default_route_table" "ocidb-route-table" {
  count                      = local.is_vcn_peering?1:0
  manage_default_resource_id = data.oci_core_vcns.ocidb_vcn.0.virtual_networks[0]["default_route_table_id"]

  # Direct all traffic for WLS VCN to local OCI DB LPG
  route_rules {
    destination       = var.wls_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.ocidb_local_peering_gateway[0].id
  }

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = data.oci_core_internet_gateways.ocidb_vcn_internet_gateway.0.gateways[0]["id"]
  }

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

/*
* Route table created when using public subnet.
* Route table for private subnet with VCN peering is created in vcn_private_subnet_config module.
*/
resource "oci_core_default_route_table" "wls-public-route-table" {
  count                      = (local.is_vcn_peering && var.assign_public_ip)?1:0
  manage_default_resource_id = data.oci_core_vcns.wls_vcn.0.virtual_networks[0]["default_route_table_id"]

  # Direct all traffic for OCI DB VCN to local WLS LPG
  route_rules {
    destination       = var.ocidb_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.wls_local_peering_gateway[0].id
  }

  route_rules {
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"

    //network_entity_id = "${lookup(data.oci_core_internet_gateways.wls_vcn_internet_gateway.gateways[0], "id")}"
    network_entity_id = var.wls_internet_gateway_id[0]
  }

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

resource "oci_core_default_route_table" "wls-private-route-table" {
  count                      = (local.is_vcn_peering && !var.assign_public_ip)?1:0
  manage_default_resource_id = data.oci_core_vcns.wls_vcn.0.virtual_networks[0]["default_route_table_id"]

  # Direct all traffic for OCI DB VCN to local WLS LPG
  route_rules {
    destination       = var.ocidb_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.wls_local_peering_gateway[0].id
  }

  route_rules {
    destination       = data.oci_core_services.tf_services.services[0]["cidr_block"]
    destination_type  = "SERVICE_CIDR_BLOCK"
    network_entity_id = join("", var.service_gateway_id)
  }

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

