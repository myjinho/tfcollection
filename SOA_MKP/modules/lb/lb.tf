/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */
/*
 * Load Balancer - This resource provides the Load Balancer resource in Oracle Cloud Infrastructure Load Balancer service.
 * See https://www.terraform.io/docs/providers/oci/r/load_balancer_load_balancer.html
 */

locals {
  /* count decides whether to provision load balancer */
  lbCount               = var.add_load_balancer == "true" ? 1 : 0
  useHttpsListenerCount = var.add_load_balancer == "true" && var.use-https == "true" ? 1 : 0
  useHttpListenerCount  = var.add_load_balancer == "true" && var.use-https == "false" ? 1 : 0
  health_check_url_path = var.is_idcs_selected == "true" ? "/cloudgate" : "/"
}

resource "oci_load_balancer_load_balancer" "wls-loadbalancer" {
  count          = local.lbCount
  shape          = var.shape
  compartment_id = var.compartment_ocid
  is_private     = var.is_private_loadbalancer
  subnet_ids     = var.subnet_ocids

  display_name = var.name

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

resource "oci_load_balancer_backend_set" "wls-lb-backendset" {
  count            = local.lbCount
  name             = var.lb_backendset_name
  load_balancer_id = oci_load_balancer_load_balancer.wls-loadbalancer[0].id
  policy           = var.lb_policy

  health_checker {
    port                = var.is_idcs_selected == "true" ? var.idcs_cloudgate_port : var.wls_ms_port
    protocol            = var.lb-protocol
    response_body_regex = ".*"
    url_path            = local.health_check_url_path
    return_code         = var.return_code
    interval_ms         = var.backend_set_health_checker_interval_ms
    timeout_in_millis   = var.backend_set_health_checker_timeout_in_millis
  }
  session_persistence_configuration {
    #Required
    cookie_name = "*"
  }
}

resource "oci_load_balancer_listener" "wls-lb-listener-http" {
  count                    = local.useHttpListenerCount
  load_balancer_id         = oci_load_balancer_load_balancer.wls-loadbalancer[0].id
  name                     = "http"
  default_backend_set_name = oci_load_balancer_backend_set.wls-lb-backendset[0].name
  port                     = var.lb-lstr-port
  protocol                 = var.lb-protocol

  connection_configuration {
    idle_timeout_in_seconds = "10"
  }
}

resource "oci_load_balancer_rule_set" "SSL_headers" {
  count            = local.useHttpsListenerCount
  load_balancer_id = oci_load_balancer_load_balancer.wls-loadbalancer[0].id
  name             = "SSLHeaders"
  items {
    action = "ADD_HTTP_REQUEST_HEADER"
    header = "WL-Proxy-SSL"
    value  = "true"
  }
  items {
    action = "ADD_HTTP_REQUEST_HEADER"
    header = "is_ssl"
    value  = "ssl"
  }
}

resource "oci_load_balancer_certificate" "wls-lb-certificate" {
  count              = local.useHttpsListenerCount
  certificate_name   = var.sslCertificateName
  load_balancer_id   = oci_load_balancer_load_balancer.wls-loadbalancer[0].id
  ca_certificate     = var.lbr_ssl_cert
  private_key        = var.lbr_ssl_pvt_key
  public_certificate = var.lbr_ssl_pub_key
}

resource "oci_load_balancer_listener" "wls-lb-listener-https" {
  count                    = local.useHttpsListenerCount
  load_balancer_id         = oci_load_balancer_load_balancer.wls-loadbalancer[0].id
  name                     = "https"
  default_backend_set_name = oci_load_balancer_backend_set.wls-lb-backendset[0].name
  port                     = var.lb-https-lstr-port
  protocol                 = var.lb-protocol
  connection_configuration {
    idle_timeout_in_seconds = "60"
  }
  rule_set_names = [oci_load_balancer_rule_set.SSL_headers[0].name]
  ssl_configuration {
    certificate_name        = oci_load_balancer_certificate.wls-lb-certificate[0].certificate_name
    verify_peer_certificate = "false"
  }
}

resource "oci_load_balancer_backend" "wls-lb-backend" {
  count            = var.add_load_balancer?var.numVMInstances:0
  load_balancer_id = oci_load_balancer_load_balancer.wls-loadbalancer[0].id
  backendset_name  = oci_load_balancer_backend_set.wls-lb-backendset[0].name
  ip_address       = var.instance_private_ips[count.index]
  port             = var.is_idcs_selected == "true" ? var.idcs_cloudgate_port : var.wls_ms_port
  backup           = false
  drain            = false
  offline          = false
  weight           = var.policy_weight
}

