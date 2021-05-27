/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */

/*
* Creates a new security lists for the specified VCN.
* Also see: https://www.terraform.io/docs/providers/oci/r/core_security_list.html
*/

locals {
  is_vcn_peering                    = var.wls_vcn_name != "" && var.existing_vcn_id != "" ? true : false
  port_for_ingress_lb_security_list = var.lb_use_https == "true" ? 443 : 80
}

/*
* Create security rules for WLS admin ports
* Usage: Weblogic subnet or bastion subnet
*
* Creates following secrules:
* egress:
*   destination 0.0.0.0/0, protocol all
* ingress:
*   Source 0.0.0.0/0, protocol TCP, Destination Port: 22 <ssh port>
*   Source 0.0.0.0/0, protocol TCP, Destination Port: <wls_extern_ssl_admin_port>
*   Source <WLS Subnet CIDR>, protocol TCP, Destination Port: ALL
*/
resource "oci_core_security_list" "wls-security-list" {
  count = var.use_existing_subnets?0:1

  #Required
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.service_name_prefix}-${var.wls_security_list_name}"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "all"
  }

  // allow inbound ssh traffic
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = 22
      max = 22
    }
  }

  // Commented out for T3/T3s Security vulnerability fix
  // allow public internet access to admin console ssl port
  //  ingress_security_rules {
  //    protocol  = "6"         // tcp
  //    source    = "0.0.0.0/0"
  //    stateless = false
  //
  //    tcp_options {
  //      "min" = "${var.wls_ssl_admin_port}"
  //      "max" = "${var.wls_ssl_admin_port}"
  //    }
  //  }
  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

/*
* Create security rules for WLS VM-VM access
* Usage: Weblogic subnet
*
* Creates following secrules:
* egress:
*   destination 0.0.0.0/0, protocol all
* ingress:
*   Source <wls_subnet_cidr>, protocol TCP, Destination Port: ALL
*/
resource "oci_core_security_list" "wls-internal-security-list" {
  count = var.use_existing_subnets?0:1

  #Required
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.service_name_prefix}-internal-security-list"

  // allow access to all ports to all VMs on the specified subnet CIDR
  ingress_security_rules {
    protocol = "6"

    // tcp
    source    = var.wls_subnet_cidr
    stateless = false
  }
  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

/*
* Create security rules for WLS Managed servers, if LB is not requested
* Usage: Weblogic subnet or bastion subnet
*
* Creates following secrules:
*   ingress:
*     Source 0.0.0.0/0, protocol TCP, Destination Port: <wls_ms_ssl_port>
*     Source 0.0.0.0/0, protocol TCP, Destination Port: <wls_ms_port>
*/
resource "oci_core_security_list" "wls-ms-security-list" {
  count = (var.use_existing_subnets || var.add_load_balancer)?0:1

  #Required
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.service_name_prefix}-wls-ms-security-list"

  // allow public internet access to managed server secure content port
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = var.wls_ms_ssl_port
      max = var.wls_ms_ssl_port
    }
  }

  // allow public internet access to managed server content port
  //  ingress_security_rules {
  //    protocol  = "6"         // tcp
  //    source    = "0.0.0.0/0"
  //    stateless = false
  //
  //    tcp_options {
  //      "min" = "${var.is_idcs_selected=="true"?var.idcs_cloudgate_port:var.wls_ms_port}"
  //      "max" = "${var.is_idcs_selected=="true"?var.idcs_cloudgate_port:var.wls_ms_port}"
  //    }
  //  }
  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

/*
* Create security rules for WLS Managed servers, if LB is requested
* Usage: Weblogic subnet
*
* Creates following secrules:
*   ingress:
*     Source <var.lb_subnet_1_cidr>, protocol TCP, Destination Port: <wls_ms_ssl_port>
*     Source <var.lb_subnet_1_cidr>, protocol TCP, Destination Port: <wls_ms_port>
*/
resource "oci_core_security_list" "wls-lb-security-list-1" {
  count = (!var.use_existing_subnets && var.add_load_balancer)?1:0

  #Required
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.service_name_prefix}-wls-lb-security-list-1"

  // allow Load balancer access to managed server secure content port
  //  ingress_security_rules {
  //    protocol  = "6"         // tcp
  //    source    = "${var.lb_subnet_1_cidr}"
  //    stateless = false
  //
  //    tcp_options {
  //      "min" = "${var.wls_ms_ssl_port}"
  //      "max" = "${var.wls_ms_ssl_port}"
  //    }
  //  }

  // allow Load Balancer access to managed server content port
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = var.lb_subnet_1_cidr
    stateless = false

    tcp_options {
      min = var.is_idcs_selected == "true" ? var.idcs_cloudgate_port : var.wls_ms_port
      max = var.is_idcs_selected == "true" ? var.idcs_cloudgate_port : var.wls_ms_port
    }
  }
  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

/*
* Create security rules for WLS Managed servers, if LB is requested and subnets are non regional
* Usage: Weblogic subnet
*
* Creates following secrules:
*   ingress:
*     Source <var.lb_subnet_1_cidr>, protocol TCP, Destination Port: <wls_ms_ssl_port>
*     Source <var.lb_subnet_1_cidr>, protocol TCP, Destination Port: <wls_ms_port>
*/
resource "oci_core_security_list" "wls-lb-security-list-2" {
  count = (var.use_existing_subnets || !var.add_load_balancer || var.use_regional_subnets || var.is_single_ad_region)?0:1

  #Required
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.service_name_prefix}-wls-lb-security-list-2"

  // allow Load Balancer access to managed server secure content port
  //  ingress_security_rules {
  //  protocol  = "6"         // tcp
  //    source    = "${var.lb_subnet_2_cidr}"
  //    stateless = false
  //
  //    tcp_options {
  //      "min" = "${var.wls_ms_ssl_port}"
  //      "max" = "${var.wls_ms_ssl_port}"
  //    }
  //  }

  // allow Load Balancer access to managed server content port
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = var.lb_subnet_2_cidr
    stateless = false

    tcp_options {
      min = var.wls_ms_port
      max = var.wls_ms_port
    }
  }
  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

/*
* Create security rules for LB
* Usage: Weblogic subnet or bastion subnet
*
* Creates following secrules:
*   egress:
*     destination 0.0.0.0/0, protocol all
*   ingress:
*     Source 0.0.0.0/0, protocol TCP, Destination Port: 80 or 443
*/
resource "oci_core_security_list" "lb-security-list" {
  count = (var.add_load_balancer && !var.use_existing_subnets)?1:0

  #Required
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
  display_name   = "${var.service_name_prefix}-lb-security-list"

  // allow outbound tcp traffic on all ports
  egress_security_rules {
    destination = "0.0.0.0/0"
    protocol    = "6" //tcp
  }

  // allow public internet access to http port
  ingress_security_rules {
    protocol  = "6" // tcp
    source    = "0.0.0.0/0"
    stateless = false

    tcp_options {
      min = local.port_for_ingress_lb_security_list
      max = local.port_for_ingress_lb_security_list
    }
  }

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

/*
* Create security rules for WLS private subnet
* Usage: Weblogic subnet
*
* Creates following secrules:
*   egress:
*     destination 0.0.0.0/0, protocol all
*   ingress:
*     Source <bastion_subnet_cidr>, protocol TCP, Destination Port: ALL
*/
resource "oci_core_security_list" "wls-bastion-security-list" {
  count          = (!var.assign_backend_public_ip && !var.use_existing_subnets && !var.use_existing_bastion)?1:0
  compartment_id = var.compartment_id
  display_name   = "${var.service_name_prefix}-wls-bastion-security-list"
  vcn_id         = var.vcn_id

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "all"
    source   = var.bastion_subnet_cidr
  }

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags
}

