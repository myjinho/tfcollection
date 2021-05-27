/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */
locals {
  empty_list = [[""]]
}

output "lb_public_ip" {
  value = coalescelist(
    oci_load_balancer_load_balancer.wls-loadbalancer.*.ip_addresses,
    local.empty_list,
  )
}

