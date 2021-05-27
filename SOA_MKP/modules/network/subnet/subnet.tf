data "oci_core_vcns" "wls_vcn" {
  #Required
  compartment_id = var.compartment_ocid

  #Optional
  filter {
    name   = "id"
    values = [var.vcn_id]
  }
}

resource "oci_core_subnet" "wls-subnet" {
  count                      = !var.use_existing_bastion?var.subnetCount:0
  availability_domain        = var.use_regional_subnet? "" : var.availability_domain
  cidr_block                 = var.cidr_block
  display_name               = var.use_regional_subnet? var.subnet_name : format("%s-%s", var.subnet_name, var.availability_domain)
  dns_label                  = var.dns_label
  compartment_id             = var.subnet_compartment_id
  vcn_id                     = var.vcn_id
  security_list_ids          = var.security_list_id
  route_table_id             = var.route_table_id
  dhcp_options_id            = var.is_vcn_peered == "true" ? data.oci_core_vcns.wls_vcn.virtual_networks[0]["default_dhcp_options_id"] : var.dhcp_options_id
  prohibit_public_ip_on_vnic = var.prohibit_public_ip

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

