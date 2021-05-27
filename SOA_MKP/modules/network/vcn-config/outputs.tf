/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */

/* Security list ids*/
output "wls_security_list_id" {
  description = "ocid of security list for WLS or bastion subnet. "
  value       = compact(concat(oci_core_security_list.wls-security-list.*.id, [""]))
}

output "wls_internal_security_list_id" {
  description = "ocid of security list for WLS public subnet. "
  value = compact(
    concat(oci_core_security_list.wls-internal-security-list.*.id, [""]),
  )
}

output "wls_ms_security_list_id" {
  description = "ocid of security list for WLS or bastion subnet. "
  value = compact(
    concat(oci_core_security_list.wls-ms-security-list.*.id, [""]),
  )
}

output "wls_lb_security-list_1_id" {
  description = "ocid of security list for WLS public/private subnet. "
  value = compact(
    concat(oci_core_security_list.wls-lb-security-list-1.*.id, [""]),
  )
}

output "wls_lb_security_list_2_id" {
  description = "ocid of security list for WLS public/private subnet. "
  value = compact(
    concat(oci_core_security_list.wls-lb-security-list-2.*.id, [""]),
  )
}

output "lb_security_list_id" {
  description = "ocid of security list for LB subnet. "
  value       = compact(concat(oci_core_security_list.lb-security-list.*.id, [""]))
}

output "wls_bastion_security_list_id" {
  description = "ocid of security list for WLS private subnet. "
  value = compact(
    concat(oci_core_security_list.wls-bastion-security-list.*.id, [""]),
  )
}

/* Route tables*/

output "route_table_id" {
  description = "ocid of route table with internet gateway. "
  value = concat(
    coalescelist(
      oci_core_default_route_table.wls-default-route-table1.*.id,
      oci_core_route_table.wls-route-table2.*.id,
      [""],
    ),
    [""],
  )
}

output "service_gateway_route_table_id" {
  description = "ocid of route table with service gateway. "
  value = element(
    coalescelist(
      oci_core_route_table.wls-service-gateway-route-table-newvcn.*.id,
      oci_core_route_table.wls-service-gateway-route-table-existingvcn.*.id,
      [""],
    ),
    0,
  )
}

/* DHCP OPTIONS */
output "dhcp_options_id" {
  description = "ocid of DHCP options. "
  value = element(
    coalescelist(
      oci_core_dhcp_options.wls-dhcp-options1.*.id,
      oci_core_default_dhcp_options.wls-dhcp-options2.*.id,
      [""],
    ),
    0,
  )
}

/* Gateways */
output "wls_internet_gateway_id" {
  value = oci_core_internet_gateway.wls-internet-gateway.*.id
}

output "wls_service_gateway_services_id" {
  description = "ocid of route table with service gateway."
  value       = data.oci_core_service_gateways.tf_service_gateways.service_gateways
}

