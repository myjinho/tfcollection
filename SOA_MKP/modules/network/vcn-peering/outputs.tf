/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */
output "is_vcn_peered" {
  value = local.is_vcn_peering
}

output "wls_dhcp_options_id" {
  value = oci_core_default_dhcp_options.wls-custom-resolver-dhcp-options.*.id
}

output "wls_dns_vm_private_ip" {
  value = join("", oci_core_instance.wls_dns_vm.*.private_ip)
}

output "wls_local_peering_gateway_id" {
  value = join(
    "",
    oci_core_local_peering_gateway.wls_local_peering_gateway.*.id,
  )
}

