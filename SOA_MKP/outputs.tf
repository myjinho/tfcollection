/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */
# Output the private and public IPs of the instance
locals {
  admin_ip_address = local.assign_weblogic_public_ip?module.compute.InstancePublicIPs[0]:module.compute.InstancePrivateIPs[0]
  admin_console_app_url = format("https://%s:%s/console",local.admin_ip_address,var.wls_extern_ssl_admin_port)
  fmw_console_app_url = local.requires_JRF?format("https://%s:%s/em",local.admin_ip_address,var.wls_extern_ssl_admin_port,):""
  sample_app_protocol = (var.add_load_balancer && var.lb_use_https)?"https":(!var.add_load_balancer)?"https":"http"
  sample_app_url_wls_ip = var.topology == "SOA with SB & B2B Cluster" ? format(
    "\nSOA Composer         : https://%s:%s/soa/composer \nB2B Console          : https://%s:%s/b2bconsole \nService Bus Console  : https://%s:%s/servicebus \nWorklist Application : https://%s:%s/integration/worklistapp",
    local.admin_ip_address,
    var.wls_ms_ssl_port,
    local.admin_ip_address,
    var.wls_ms_ssl_port,
    local.admin_ip_address,
    var.wls_extern_ssl_admin_port,
    local.admin_ip_address,
    var.wls_ms_ssl_port,
    ) : var.topology == "MFT Cluster" ? format(
    "\nMFT Console : https://%s:%s/mftconsole",
    local.admin_ip_address,
    var.wls_ms_ssl_port,
  ) : ""
  sample_app_url_lb_ip = (var.topology == "SOA with SB & B2B Cluster" && var.add_load_balancer)?format(
    "\nSOA Composer         : %s://%s/soa/composer \nB2B Console          : %s://%s/b2bconsole \nService Bus Console  : https://%s:%s/servicebus \nWorklist Application : %s://%s/integration/worklistapp",
    local.sample_app_protocol,
    element(module.lb.lb_public_ip[0], 0),
    local.sample_app_protocol,
    element(module.lb.lb_public_ip[0], 0),
    local.admin_ip_address,
    var.wls_extern_ssl_admin_port,
    local.sample_app_protocol,
    element(module.lb.lb_public_ip[0], 0),
    ):(var.topology == "MFT Cluster" && var.add_load_balancer)?format(
    "\nMFT Console : %s://%s/mftconsole",
    local.sample_app_protocol,
    element(module.lb.lb_public_ip[0], 0),
  ):""
  sample_app_url = var.add_load_balancer?local.sample_app_url_lb_ip:local.sample_app_url_wls_ip
  sample_idcs_app_url = (var.deploy_sample_app && var.add_load_balancer && var.is_idcs_selected)?format(
    "%s://%s/__protected/idcs-sample-app",
    local.sample_app_protocol,
    element(module.lb.lb_public_ip[0], 0),
  ) : ""
}

output "Virtual_Cloud_Network_Id" {
  value = module.network-vcn.VcnID
}

output "Loadbalancer_Subnets_Id" {
  value = compact(
    concat(
      module.network-lb-subnet-1.subnet_id,
      module.network-lb-subnet-2.subnet_id,
    ),
  )
}

output "Instance_Subnet_Id" {
  value = distinct(
    compact(
      concat(
        module.network-wls-public-subnet.subnet_id,
        module.network-wls-private-subnet.subnet_id,
      ),
    ),
  )
}

output "Loadbalancer_Public_Ip" {
  value = flatten(module.lb.lb_public_ip[0])
}

#output "Bastion_Instance" {
#  value = "${
#    formatlist(
#      "{
#       \"Instance Id\":\"%s\",
#       \"Instance Name\":\"%s\",
#       \"Private IP\":\"%s\",
#       \"Public IP\":\"%s\"
#       }",
#      module.bastion-compute.id,
#      module.bastion-compute.display_name,
#      module.bastion-compute.privateIp,
#      module.bastion-compute.publicIp
#    )}"
#}

output "Service_Instances" {
  value = join(" ", formatlist(
    "{\n       Instance Id   :%s,	  \n       Instance name :%s,	  \n       Private IP    :%s,	  \n       Public IP     :%s\n}",
    module.compute.InstanceOcids,
    module.compute.display_names,
    module.compute.InstancePrivateIPs,
    module.compute.InstancePublicIPs,
  ))
}

output "Version" {
  value = format("%s %s", module.compute.WlsVersion, local.prov_type)
}

output "Weblogic_Administration_Console" {
  value = local.admin_console_app_url
}

output "FMW_Console" {
  value = local.fmw_console_app_url
}

output "Service_Consoles" {
  value = local.sample_app_url
}

#output "Sample_Application_protected_by_IDCS" {
#  value="${local.sample_idcs_app_url}"
#}
