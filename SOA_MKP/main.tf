/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */

locals {
  compartment_ocid = var.compartment_ocid
  numVMInstances   = var.wls_scaleout_node_count == ""?var.wls_node_count:(var.wls_scaleout_node_count == var.wls_node_count)?var.wls_node_count:var.wls_scaleout_node_count
  is_atp_db        = trimspace(var.atp_db_id) == "" ? false : true

  // Default DB user for ATP DB is admin
  db_user                   = local.is_atp_db ? "ADMIN" : var.oci_db_user
  db_password               = local.is_atp_db ? var.atp_db_password : var.oci_db_password
  is_oci_db                 = trimspace(var.ocidb_dbsystem_id) == "" ? false : true
  assign_weblogic_public_ip = var.assign_weblogic_public_ip && var.subnet_type == "Use Public Subnet" ? true : false
  use_existing_bastion      = var.bastion_strategy == "Use Existing Bastion Instance" ? true : false
  bastion_subnet_cidr       = var.bastion_subnet_cidr == "" && var.wls_vcn_name != "" && local.assign_weblogic_public_ip == "false" ? "10.0.6.0/24" : var.bastion_subnet_cidr
  wls_subnet_cidr           = var.wls_subnet_cidr == "" && var.wls_vcn_name != "" ? "10.0.3.0/24" : var.wls_subnet_cidr
  lb_subnet_1_subnet_cidr   = var.lb_subnet_1_cidr == "" && var.wls_vcn_name != "" ? "10.0.4.0/24" : var.lb_subnet_1_cidr
  lb_subnet_2_subnet_cidr   = var.lb_subnet_2_cidr == "" && var.wls_vcn_name != "" ? "10.0.5.0/24" : var.lb_subnet_2_cidr
  tf_version_file           = "version.txt"
  use_existing_subnets      = var.wls_subnet_id == "" && var.lb_subnet_1_id == "" && var.lb_subnet_2_id == "" ? false : true

  #service_name              = "${var.service_name}${substr(uuid(), 0,8)}"
  # Remove all characters from the service_name that dont satisfy the criteria:
  # must start with letter, must only contain letters and numbers and length between 1,8
  # See https://github.com/google/re2/wiki/Syntax
  service_name_prefix      = replace(var.service_name, "/[^a-zA-Z0-9]/", "")
  requires_JRF             = local.is_oci_db || local.is_atp_db ? true : false
  prov_type                = local.requires_JRF ? local.is_atp_db ? "(JRF with ATP DB)" : "(JRF with OCI DB)" : "(Non JRF)"
  use_regional_subnet      = var.use_regional_subnet && var.subnet_span == "Regional Subnet" ? true : false
  network_compartment_id   = var.network_compartment_id == "" ? var.compartment_ocid : var.network_compartment_id
  subnet_compartment_id    = var.subnet_compartment_id == "" ? local.network_compartment_id : var.subnet_compartment_id
  lb_subnet_compartment_id = var.lb_subnet_compartment_id == "" ? local.network_compartment_id : var.lb_subnet_compartment_id
  bastion_subnet_compartment_id = var.bastion_subnet_compartment_id == "" ? local.network_compartment_id : var.bastion_subnet_compartment_id

  #Availability Domains
  ad_names                    = compact(data.template_file.ad_names.*.rendered)
  bastion_availability_domain = local.use_regional_subnet ? local.ad_names[0] : (var.bastion_subnet_id == "" ? var.wls_availability_domain_name : data.oci_core_subnet.bastion_subnet[0].availability_domain)
  #for existing wls subnet, get AD from the subnet
  wls_availability_domain      = local.use_regional_subnet ? local.ad_names[0] : (var.wls_subnet_id == "" ? var.wls_availability_domain_name : data.oci_core_subnet.wls_subnet[0].availability_domain)
  
  #map of Tag key and value
  #special chars string denotes empty values for tags for validation purposes
  #otherwise zipmap function below fails first for empty strings before validators executed
  use_defined_tags = var.defined_tag == "~!@#$%^&*()" && var.defined_tag_value == "~!@#$%^&*()" ? false : true

  use_freeform_tags = var.free_form_tag == "~!@#$%^&*()" && var.free_form_tag_value == "~!@#$%^&*()" ? false : true

  #ignore defaults of special chars if tags are not provided
  defined_tag         = false == local.use_defined_tags ? "" : var.defined_tag
  defined_tag_value   = false == local.use_defined_tags ? "" : var.defined_tag_value
  free_form_tag       = false == local.use_freeform_tags ? "" : var.free_form_tag
  free_form_tag_value = false == local.use_freeform_tags ? "" : var.free_form_tag_value
  lbr_ssl_cert        = file("${path.module}/CombinedDigicertCA.cer")
  lbr_ssl_pvt_key     = file("${path.module}/star_soa_ocp_oraclecloud_com.key")
  lbr_ssl_pub_key     = file("${path.module}/_.soa.ocp.oraclecloud.com.crt")

  defined_tags = zipmap(
    compact([trimspace(local.defined_tag)]),
    compact([trimspace(local.defined_tag_value)]),
  )
  freeform_tags = zipmap(
    compact([trimspace(local.free_form_tag)]),
    compact([trimspace(local.free_form_tag_value)]),
  )
}

module "validators" {
  source = "./modules/validators"

  original_service_name = var.service_name
  service_name_prefix   = local.service_name_prefix
  numVMInstances        = local.numVMInstances
  existing_vcn_id       = var.existing_vcn_id
  wls_subnet_cidr       = var.wls_subnet_cidr
  lb_subnet_1_cidr      = var.lb_subnet_1_cidr
  lb_subnet_2_cidr      = var.lb_subnet_2_cidr
  bastion_subnet_cidr   = var.bastion_subnet_cidr
  assign_public_ip      = local.assign_weblogic_public_ip
  add_load_balancer     = var.add_load_balancer
  is_idcs_selected      = var.is_idcs_selected
  idcs_host             = var.idcs_host
  idcs_tenant           = var.idcs_tenant
  idcs_client_id        = var.idcs_client_id
  idcs_client_secret    = var.idcs_client_secret
  idcs_cloudgate_port   = var.idcs_cloudgate_port

  instance_shape = var.instance_shape

  wls_admin_user     = var.wls_admin_user
  wls_admin_password = var.wls_admin_password

  wls_nm_port               = var.wls_nm_port
  wls_console_port          = var.wls_console_port
  wls_console_ssl_port      = var.wls_console_ssl_port
  wls_ms_port               = var.wls_ms_port
  wls_ms_ssl_port           = var.wls_ms_ssl_port
  wls_cluster_mc_port       = var.wls_cluster_mc_port
  wls_extern_admin_port     = var.wls_extern_admin_port
  wls_extern_ssl_admin_port = var.wls_extern_ssl_admin_port

  wls_availability_domain_name = local.wls_availability_domain
  lb_availability_domain_name1 = var.lb_subnet_1_availability_domain_name
  lb_availability_domain_name2 = var.lb_subnet_2_availability_domain_name
  wls_subnet_id                = var.wls_subnet_id
  lb_subnet_1_id               = var.lb_subnet_1_id
  lb_subnet_2_id               = var.lb_subnet_2_id
  bastion_subnet_id            = var.bastion_subnet_id

  // WLS version and edition
  wls_version = var.wls_version
  wls_edition = var.wls_edition
  log_level   = var.log_level
  vcn_name    = var.wls_vcn_name

  //soacs Topologies
  topology = var.topology

  // OCI DB Params
  ocidb_compartment_id   = var.ocidb_compartment_id
  ocidb_dbsystem_id      = var.ocidb_dbsystem_id
  ocidb_database_id      = var.ocidb_database_id
  ocidb_pdb_service_name = var.ocidb_pdb_service_name
  is_oci_db              = local.is_oci_db

  // ATP DB Params
  is_atp_db             = local.is_atp_db ? "true" : "false"
  atp_db_level          = var.atp_db_level
  atp_db_id             = var.atp_db_id
  atp_db_compartment_id = var.atp_db_compartment_id

  // Common params
  db_user     = local.db_user
  db_password = local.db_password

  // VCN peering variables for OCI DB
  ocidb_dns_subnet_cidr = var.ocidb_dns_subnet_cidr
  ocidb_vcn_cidr        = var.ocidb_vcn_cidr

  wls_dns_subnet_cidr = var.wls_dns_subnet_cidr

  use_regional_subnet = local.use_regional_subnet

  // KMS
  kms_key_id             = var.kms_key_id
  kms_service_endpoint   = var.kms_key_id
  use_kms_decryption     = var.use_kms_decryption
  atp_db_wallet_password = var.atp_db_wallet_password
  defined_tag            = var.defined_tag
  defined_tag_value      = var.defined_tag_value
  freeform_tag           = var.free_form_tag
  freeform_tag_value     = var.free_form_tag_value
}

module "compute-keygen" {
  source = "./modules/compute/keygen"
}

module "network-vcn" {
  source = "./modules/network/vcn"

  compartment_ocid = local.network_compartment_id

  // New VCN is created if vcn_name is not empty
  // Existing vcn_id is returned back without creating a new VCN if vcn_name is empty but vcn_id is provided.
  vcn_name = var.wls_vcn_name

  vcn_id               = var.existing_vcn_id
  wls_vcn_cidr         = var.wls_vcn_cidr
  use_existing_subnets = local.use_existing_subnets
  service_name_prefix  = substr(local.service_name_prefix,0,11)
  defined_tags         = local.defined_tags
  freeform_tags        = local.freeform_tags
}

/* Adds new dhcp options, security list, route table */
module "network-vcn-config" {
  source = "./modules/network/vcn-config"

  compartment_id        = local.network_compartment_id

  //vcn id if new is created
  vcn_id          = module.network-vcn.VcnID
  existing_vcn_id = var.existing_vcn_id

  wls_ssl_admin_port          = var.wls_extern_ssl_admin_port
  wls_ms_port                 = var.wls_ms_port
  wls_ms_ssl_port             = var.wls_ms_ssl_port
  wls_admin_port              = var.wls_extern_admin_port
  enable_admin_console_access = var.enable_admin_console_access
  dhcp_options_name           = local.assign_weblogic_public_ip == "false" ? "bastion-dhcpOptions" : "dhcpOptions"
  wls_security_list_name      = local.assign_weblogic_public_ip == "false" ? "bastion-security-list" : "wls-security-list"
  wls_subnet_cidr             = local.wls_subnet_cidr
  lb_subnet_2_cidr            = local.lb_subnet_2_subnet_cidr
  lb_subnet_1_cidr            = local.lb_subnet_1_subnet_cidr
  add_load_balancer           = var.add_load_balancer
  lb_use_https                = var.lb_use_https
  wls_vcn_name                = var.wls_vcn_name
  use_existing_subnets        = local.use_existing_subnets
  service_name_prefix         = local.service_name_prefix
  assign_backend_public_ip    = local.assign_weblogic_public_ip
  use_regional_subnets        = local.use_regional_subnet
  use_existing_bastion        = local.use_existing_bastion
  bastion_subnet_cidr         = local.bastion_subnet_cidr
  is_single_ad_region         = local.is_single_ad_region
  is_idcs_selected            = var.is_idcs_selected
  idcs_cloudgate_port         = var.idcs_cloudgate_port
  defined_tags                = local.defined_tags
  freeform_tags               = local.freeform_tags
}

/* Create primary subnet for Load balancer only */
module "network-lb-subnet-1" {
  source              = "./modules/network/subnet"
  service_name_prefix = local.service_name_prefix
  compartment_ocid    = local.network_compartment_id
  subnet_compartment_id = local.lb_subnet_compartment_id
  tenancy_ocid        = var.tenancy_ocid
  vcn_id              = module.network-vcn.VcnID
  security_list_id    = module.network-vcn-config.lb_security_list_id
  dhcp_options_id     = module.network-vcn-config.dhcp_options_id
  route_table_id      = module.network-vcn-config.route_table_id[0]

  subnet_name         = "${local.service_name_prefix}-${var.lb_subnet_1_name}"
  dns_label           = substr("sublb1${local.service_name_prefix}",0,14)
  cidr_block          = local.lb_subnet_1_subnet_cidr
  availability_domain = var.lb_subnet_1_availability_domain_name
  subnetCount         = (var.add_load_balancer && var.lb_subnet_1_id == "")?1:0
  subnet_id           = var.lb_subnet_1_id
  use_regional_subnet = local.use_regional_subnet
  prohibit_public_ip  = var.lb_subnet_type == "Use Public Subnet" ? false : true
  defined_tags        = local.defined_tags
  freeform_tags       = local.freeform_tags
}

/* Create secondary subnet for wls and lb backend */
module "network-lb-subnet-2" {
  source              = "./modules/network/subnet"
  service_name_prefix = local.service_name_prefix
  compartment_ocid    = local.network_compartment_id
  subnet_compartment_id    = local.lb_subnet_compartment_id
  tenancy_ocid        = var.tenancy_ocid
  vcn_id              = module.network-vcn.VcnID
  security_list_id    = module.network-vcn-config.lb_security_list_id
  dhcp_options_id     = module.network-vcn-config.dhcp_options_id
  route_table_id      = module.network-vcn-config.route_table_id[0]
  subnet_name         = "${local.service_name_prefix}-${var.lb_subnet_2_name}"
  dns_label           = substr("sublb2${local.service_name_prefix}",0,14)
  cidr_block          = local.lb_subnet_2_subnet_cidr
  availability_domain = var.lb_subnet_2_availability_domain_name
  subnetCount         = (var.add_load_balancer&& var.lb_subnet_2_id == "" && !local.use_regional_subnet && !local.is_single_ad_region)?1:0
  subnet_id           = var.lb_subnet_2_id
  use_regional_subnet = local.use_regional_subnet
  prohibit_public_ip  = var.lb_subnet_type == "Use Public Subnet" ? false : true
  defined_tags        = local.defined_tags
  freeform_tags       = local.freeform_tags
}

/* Create back end subnet for wls and lb backend */
module "network-bastion-subnet" {
  source              = "./modules/network/subnet"
  service_name_prefix = local.service_name_prefix
  subnet_compartment_id = local.bastion_subnet_compartment_id
  compartment_ocid    = local.network_compartment_id
  tenancy_ocid        = var.tenancy_ocid
  vcn_id              = module.network-vcn.VcnID
  security_list_id = compact(
    concat(
      module.network-vcn-config.wls_security_list_id,
      module.network-vcn-config.wls_ms_security_list_id,
    ),
  )
  dhcp_options_id     = module.network-vcn-config.dhcp_options_id
  route_table_id      = module.network-vcn-config.route_table_id[0]
  subnet_name         = "${local.service_name_prefix}-${var.bastion_subnet_name}"
  dns_label           = substr("subbtn${local.service_name_prefix}",0,14)
  cidr_block          = local.bastion_subnet_cidr
  availability_domain = local.bastion_availability_domain
  subnetCount         = (!local.assign_weblogic_public_ip && var.bastion_subnet_id == "")?1:0
  subnet_id           = var.bastion_subnet_id
  use_regional_subnet = local.use_regional_subnet
  prohibit_public_ip  = "false"
  use_existing_bastion= local.use_existing_bastion
  defined_tags        = local.defined_tags
  freeform_tags       = local.freeform_tags
}

module "bastion-compute" {
  source = "./modules/compute/bastion-instance"

  tenancy_ocid        = var.tenancy_ocid
  compartment_ocid    = local.compartment_ocid
  availability_domain = local.bastion_availability_domain
  opc_key             = module.compute-keygen.OPCPrivateKey
  ssh_public_key      = var.ssh_public_key
  bastion_subnet_ocid = element(module.network-bastion-subnet.subnet_id,0)
  instance_shape      = var.bastion_instance_shape
  instance_count      = !local.assign_weblogic_public_ip?1:0
  region              = var.region
  instance_name       = "${local.service_name_prefix}-bastion-instance"
  use_existing_bastion= local.use_existing_bastion

  #  instance_image_id   = "${var.bastion_instance_image_id[var.region]}"
  defined_tags  = local.defined_tags
  freeform_tags = local.freeform_tags
}

module "network-dns-vms" {
  source              = "./modules/network/vcn-peering"
  service_name_prefix = local.service_name_prefix
  tenancy_ocid        = var.tenancy_ocid
  compartment_ocid    = local.network_compartment_id
  instance_shape      = var.instance_shape
  region              = var.region

  wls_availability_domain = local.wls_availability_domain
  ssh_public_key          = var.ssh_public_key

  wls_vcn_id          = module.network-vcn.VcnID
  wls_vcn_cidr        = var.wls_vcn_cidr
  existing_vcn_id     = var.existing_vcn_id
  wls_vcn_name        = var.wls_vcn_name
  wls_dns_subnet_cidr = var.wls_dns_subnet_cidr

  ocidb_database_id    = var.ocidb_database_id
  ocidb_compartment_id = var.ocidb_compartment_id
  ocidb_dbsystem_id    = trimspace(var.ocidb_dbsystem_id)
  ocidb_vcn_cidr       = var.ocidb_vcn_cidr

  ocidb_dns_subnet_cidr = var.ocidb_dns_subnet_cidr

  // Adding dependency on vcn-config module
  wls_internet_gateway_id = module.network-vcn-config.wls_internet_gateway_id

  // Private subnet support
  bastion_host_private_key = module.compute-keygen.OPCPrivateKey["private_key_pem"]
  bastion_host             = join("", module.bastion-compute.publicIp)
  assign_public_ip         = local.assign_weblogic_public_ip
  use_regional_subnet      = local.use_regional_subnet
  service_gateway_id       = module.network-vcn-config.wls_service_gateway_services_id
  defined_tags             = local.defined_tags
  freeform_tags            = local.freeform_tags
}

/* Create back end  private subnet for wls */
module "network-wls-private-subnet" {
  source              = "./modules/network/subnet"
  service_name_prefix = local.service_name_prefix
  compartment_ocid    = local.network_compartment_id
  subnet_compartment_id    = local.subnet_compartment_id
  tenancy_ocid        = var.tenancy_ocid
  vcn_id              = module.network-vcn.VcnID
  security_list_id = compact(
    concat(
      module.network-vcn-config.wls_bastion_security_list_id,
      module.network-vcn-config.wls_internal_security_list_id,
      module.network-vcn-config.wls_lb_security-list_1_id,
      module.network-vcn-config.wls_lb_security_list_2_id,
    ),
  )
  dhcp_options_id     = module.network-vcn-config.dhcp_options_id
  route_table_id      = module.network-vcn-config.service_gateway_route_table_id
  subnet_name         = "${local.service_name_prefix}-${var.wls_subnet_name}"
  dns_label           = substr("subpvt${local.service_name_prefix}",0,14)
  cidr_block          = local.wls_subnet_cidr
  availability_domain = local.wls_availability_domain
  is_vcn_peered       = module.network-dns-vms.is_vcn_peered ? "true" : "false"
  subnetCount         = (!local.assign_weblogic_public_ip && var.wls_subnet_id == "")?1:0
  subnet_id           = var.wls_subnet_id
  prohibit_public_ip  = "true"
  use_regional_subnet = local.use_regional_subnet
  defined_tags        = local.defined_tags
  freeform_tags       = local.freeform_tags
}

/* Create back end  public subnet for wls */
module "network-wls-public-subnet" {
  source              = "./modules/network/subnet"
  service_name_prefix = local.service_name_prefix
  compartment_ocid    = local.network_compartment_id
  subnet_compartment_id    = local.subnet_compartment_id
  tenancy_ocid        = var.tenancy_ocid
  vcn_id              = module.network-vcn.VcnID
  security_list_id = compact(
    concat(
      module.network-vcn-config.wls_security_list_id,
      module.network-vcn-config.wls_ms_security_list_id,
      module.network-vcn-config.wls_internal_security_list_id,
      module.network-vcn-config.wls_lb_security-list_1_id,
      module.network-vcn-config.wls_lb_security_list_2_id,
    ),
  )
  dhcp_options_id      = module.network-vcn-config.dhcp_options_id
  route_table_id       = module.network-vcn-config.route_table_id[0]
  subnet_name          = "${local.service_name_prefix}-${var.wls_subnet_name}"
  dns_label            = substr("subpub${local.service_name_prefix}",0,14)
  cidr_block           = local.wls_subnet_cidr
  availability_domain  = local.wls_availability_domain
  is_vcn_peered        = module.network-dns-vms.is_vcn_peered ? "true" : "false"
  subnetCount          = (local.assign_weblogic_public_ip && var.wls_subnet_id == "")?1:0
  subnet_id            = var.wls_subnet_id
  prohibit_public_ip   = "false"
  use_existing_subnets = local.use_existing_subnets
  use_regional_subnet  = local.use_regional_subnet
  defined_tags         = local.defined_tags
  freeform_tags        = local.freeform_tags
}

module "compute" {
  source              = "./modules/compute/instance"
  tf_script_version   = file(local.tf_version_file)
  tenancy_ocid        = var.tenancy_ocid
  compartment_ocid    = local.compartment_ocid
  instance_image_ocid = var.instance_image_id
  numVMInstances      = local.numVMInstances
  availability_domain = local.wls_availability_domain
  subnet_ocid = local.assign_weblogic_public_ip?element(module.network-wls-public-subnet.subnet_id,0):element(module.network-wls-private-subnet.subnet_id,0)
  wls_subnet_id            = var.wls_subnet_id
  region                    = var.region
  use_regional_subnet  = local.use_regional_subnet
  ssh_public_key            = var.ssh_public_key
  instance_shape            = var.instance_shape
  volume_size               = var.volume_size
  wls_admin_user            = var.wls_admin_user
  wls_domain_name           = format("%s_domain", local.service_name_prefix)
  wls_admin_password        = var.wls_admin_password
  use_custom_nm_password    = var.use_custom_nm_password
  wls_nm_password           = var.wls_nm_password
  compute_name_prefix       = local.service_name_prefix
  wls_nm_port               = var.wls_nm_port
  wls_ms_server_name        = format("%s_server_", local.service_name_prefix)
  wls_admin_server_name     = format("%s_adminserver", local.service_name_prefix)
  wls_ms_port               = var.wls_ms_port
  wls_ms_ssl_port           = var.wls_ms_ssl_port
  wls_cluster_name          = format("%s_cluster", local.service_name_prefix)
  wls_machine_name          = format("%s_machine_", local.service_name_prefix)
  wls_extern_admin_port     = var.wls_extern_admin_port
  wls_extern_ssl_admin_port = var.wls_extern_ssl_admin_port
  wls_console_port          = var.wls_console_port
  wls_console_ssl_port      = var.wls_console_ssl_port
  wls_edition               = var.wls_edition
  is_idcs_selected          = var.is_idcs_selected
  idcs_host                 = var.idcs_host
  idcs_port                 = var.idcs_port
  idcs_tenant               = var.idcs_tenant
  idcs_client_id            = var.idcs_client_id
  idcs_cloudgate_port       = var.idcs_cloudgate_port
  idcs_app_prefix           = local.service_name_prefix

  // DB params - to generate a connect string from the params
  db_user     = local.db_user
  db_password = local.db_password

  // OCI DB params
  ocidb_compartment_id   = var.ocidb_compartment_id
  ocidb_database_id      = var.ocidb_database_id
  ocidb_dbsystem_id      = trimspace(var.ocidb_dbsystem_id)
  ocidb_pdb_service_name = var.ocidb_pdb_service_name
  ocidb_db_port          = var.oci_db_port

  // ATP DB params
  atp_db_level = var.atp_db_level
  atp_db_id    = trimspace(var.atp_db_id)

  // Dev or Prod mode
  mode      = var.mode
  log_level = var.log_level

  deploy_sample_app = var.deploy_sample_app

  // WLS version and artifacts
  wls_version = var.wls_version

  //soacs Topologies
  topology                 = var.topology
  use_schema_partitioning  = var.use_schema_partitioning
  use_custom_schema_prefix = var.use_custom_schema_prefix
  rcu_schema_prefix        = var.rcu_schema_prefix
  use_custom_schema_password = var.use_custom_schema_password

  // for VCN peering
  is_vcn_peered = module.network-dns-vms.is_vcn_peered ? "true" : "false"
  wls_dns_vm_ip = module.network-dns-vms.wls_dns_vm_private_ip

  assign_public_ip   = local.assign_weblogic_public_ip
  opc_key            = module.compute-keygen.OPCPrivateKey
  oracle_key         = module.compute-keygen.OraclePrivateKey
  use_kms_decryption = var.use_kms_decryption
  lb_use_https       = var.lb_use_https
  defined_tags       = local.defined_tags
  freeform_tags      = local.freeform_tags
}

module "lb" {
  source = "./modules/lb"

  add_load_balancer = var.add_load_balancer
  compartment_ocid  = local.lb_subnet_compartment_id
  tenancy_ocid      = var.tenancy_ocid
  subnet_ocids = compact(
    concat(
      compact(module.network-lb-subnet-1.subnet_id),
      compact(module.network-lb-subnet-2.subnet_id),
    ),
  )
  instance_private_ips    = module.compute.InstancePrivateIPs
  wls_ms_port             = var.wls_ms_port
  numVMInstances          = local.numVMInstances
  name                    = "${local.service_name_prefix}-lb"
  sslCertificateName      = "${local.service_name_prefix}-lb-cert"
  lb_backendset_name      = "${local.service_name_prefix}-lb-backendset"
  shape                   = var.lb_shape
  use-https               = var.lb_use_https
  is_idcs_selected        = var.is_idcs_selected
  idcs_cloudgate_port     = var.idcs_cloudgate_port
  lbr_ssl_cert            = local.lbr_ssl_cert
  lbr_ssl_pub_key         = local.lbr_ssl_pub_key
  lbr_ssl_pvt_key         = local.lbr_ssl_pvt_key
  is_private_loadbalancer = var.lb_subnet_type == "Use Public Subnet" ? false : true
  defined_tags            = local.defined_tags
  freeform_tags           = local.freeform_tags
}

module "provisioners" {
  source = "./modules/provisioners"

  ssh_private_key = module.compute-keygen.OPCPrivateKey["private_key_pem"]
  host_ips = coalescelist(
    compact(module.compute.InstancePublicIPs),
    compact(module.compute.InstancePrivateIPs),
  )
  admin_ip                 = coalesce(module.compute.PublicAdminIP, module.compute.PrivateAdminIP)
  numVMInstances           = local.numVMInstances
  volumeAttachmentInfo     = module.compute.VolumeAttachmentInfo
  is_atp_db                = local.is_atp_db ? "true" : "false"
  atp_db_id                = var.atp_db_id
  wls_admin_password       = var.wls_admin_password
  wls_nm_password          = var.wls_nm_password
  db_password              = local.db_password
  rcu_schema_password      = var.rcu_schema_password
  mode                     = var.mode
  bastion_host_private_key = local.use_existing_bastion?var.bastion_ssh_pvt_key:module.compute-keygen.OPCPrivateKey["private_key_pem"]
  bastion_host             = local.use_existing_bastion?var.bastion_public_ip:join("", module.bastion-compute.publicIp)
  assign_public_ip         = local.assign_weblogic_public_ip
  oracle_key               = module.compute-keygen.OraclePrivateKey
  kms_key_id               = var.kms_key_id
  kms_service_endpoint     = var.kms_service_endpoint
  use_kms_decryption       = var.use_kms_decryption
  atp_db_wallet_password   = var.atp_db_wallet_password
  instance_ids             = module.compute.InstanceOcids
  add_load_balancer        = var.add_load_balancer
  lb_public_ip             = flatten(module.lb.lb_public_ip[0])
  idcs_client_secret       = var.idcs_client_secret
}

