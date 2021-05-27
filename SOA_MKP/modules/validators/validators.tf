/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */

locals {
  validators_msg_map = {} #Dummy map to trigger an error in case we detect a validation error.

  invalid_service_name_prefix = length(var.service_name_prefix) > 15 || length(var.service_name_prefix) < 1 || length(
    replace(substr(var.service_name_prefix, 0, 1), "/[0-9]/", ""),
  ) == 0 || length(var.service_name_prefix) != length(var.original_service_name)
  invalid_vm_count = var.numVMInstances < 1 && var.numVMInstances > 16

  invalid_lb_availability_domain_indexes = var.use_regional_subnet == false && var.add_load_balancer == "true" && var.lb_availability_domain_name1 != "" && var.lb_availability_domain_name1 == var.lb_availability_domain_name2

  invalid_mft_atp_selected          = var.topology == "MFT Cluster" && var.is_atp_db == "true"
  invalid_bam_atp_selected          = var.topology == "BAM Cluster" && var.is_atp_db == "true"
  #invalid_bam_multinode_selected    = var.topology == "BAM Cluster" && var.numVMInstances > 1
  invalid_wls_edition               = !contains(["SE", "EE", "SUITE"], var.wls_edition)
  invalid_wls_version               = !contains(["12.2.1.4", "12.2.1.3", "11.1.1.7"], var.wls_version)
  is11gVersion                      = var.wls_version == "11.1.1.7"
  isNonJRF                          = !var.is_atp_db && !var.is_oci_db
  invalid_atp_db_not_allowed        = local.is11gVersion && var.is_atp_db || local.isNonJRF
  invalid_wls_console_port          = var.wls_console_port < 0
  invalid_wls_console_ssl_port      = var.wls_console_ssl_port < 0
  invalid_wls_extern_admin_port     = var.wls_extern_admin_port < 0
  invalid_wls_extern_ssl_admin_port = var.wls_extern_ssl_admin_port < 0
  invalid_wls_nm_port               = var.wls_nm_port < 0
  invalid_wls_ms_port               = var.wls_ms_port < 0
  invalid_wls_cluster_mc_port       = var.wls_cluster_mc_port < 0
  has_wls_subnet_cidr               = var.wls_subnet_cidr == ""
  has_mgmt_subnet_cidr              = var.bastion_subnet_cidr == ""
  has_lb_subnet_1_cidr              = var.add_load_balancer == "true" && var.lb_subnet_1_cidr == ""
  has_lb_subnet_2_cidr              = var.add_load_balancer == "true" && var.lb_subnet_2_cidr == ""
  missing_wls_subnet_cidr           = var.existing_vcn_id != "" && var.wls_subnet_id == "" ? local.has_wls_subnet_cidr : false
  missing_lb_subnet_1_cidr          = var.existing_vcn_id != "" && var.lb_subnet_1_id == "" ? local.has_lb_subnet_1_cidr : false

  //missing_lb_subnet_2_cidr          = "${var.existing_vcn_id!="" && var.lb_subnet_2_id=="" && var.use_regional_subnet == "false" && local.is_single_ad_region == "false"?local.has_lb_subnet_2_cidr: 0}"
  missing_mgmt_backend_subnet_cidr = var.existing_vcn_id != "" && var.assign_public_ip == "false" && var.bastion_subnet_id == "" ? local.has_mgmt_subnet_cidr : false

  duplicate_wls_subnet_cidr_with_lb1_cidr            = var.add_load_balancer == "true" && local.has_lb_subnet_1_cidr == 0 && local.has_wls_subnet_cidr == 0 && var.wls_subnet_cidr == var.lb_subnet_1_cidr
  duplicate_wls_subnet_cidr_with_lb2_cidr            = var.add_load_balancer == "true" && var.use_regional_subnet == "false" && local.has_lb_subnet_2_cidr == 0 && local.has_wls_subnet_cidr == 0 && var.wls_subnet_cidr == var.lb_subnet_2_cidr
  duplicate_wls_subnet_cidr_with_private_subnet_cidr = var.existing_vcn_id == "" && var.assign_public_ip == "false" && var.bastion_subnet_id == "" && local.has_mgmt_subnet_cidr == 0 && local.has_wls_subnet_cidr == 0 && var.wls_subnet_cidr == var.bastion_subnet_cidr

  check_duplicate_wls_subnet_cidr = var.wls_subnet_cidr != "" && (local.duplicate_wls_subnet_cidr_with_lb1_cidr || local.duplicate_wls_subnet_cidr_with_lb2_cidr || local.duplicate_wls_subnet_cidr_with_private_subnet_cidr)

  #lb1 check
  duplicate_lb1_subnet_cidr_with_lb2_cidr            = var.add_load_balancer == "true" && var.use_regional_subnet == "false" && local.has_lb_subnet_1_cidr == 0 && local.has_lb_subnet_2_cidr == 0 && var.lb_subnet_1_cidr == var.lb_subnet_2_cidr
  duplicate_lb1_subnet_cidr_with_private_subnet_cidr = var.assign_public_ip == "false" && var.bastion_subnet_id == "" && local.has_mgmt_subnet_cidr == 0 && local.has_lb_subnet_1_cidr == 0 && var.lb_subnet_1_cidr == var.bastion_subnet_cidr

  check_duplicate_lb1_subnet_cidr = local.has_lb_subnet_1_cidr == 0 && (local.duplicate_lb1_subnet_cidr_with_lb2_cidr || local.duplicate_lb1_subnet_cidr_with_private_subnet_cidr)

  #lb2 check
  duplicate_lb2_subnet_cidr_with_private_subnet_cidr = var.add_load_balancer == "true" && var.use_regional_subnet == "false" && var.assign_public_ip == "false" && var.bastion_subnet_id == "" && local.has_mgmt_subnet_cidr == 0 && local.has_lb_subnet_2_cidr == 0 && var.lb_subnet_2_cidr == var.bastion_subnet_cidr
  check_duplicate_lb2_subnet_cidr                    = local.has_lb_subnet_2_cidr == 0 && local.duplicate_lb2_subnet_cidr_with_private_subnet_cidr

  #multiple infra db
  invalid_multiple_infra_dbs = var.is_oci_db && var.is_atp_db
  invalid_log_level = !contains(
    ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"],
    var.log_level,
  )
  missing_vcn                     = var.existing_vcn_id == "" && var.vcn_name == ""
  has_existing_vcn                = var.existing_vcn_id != ""
  has_vcn_name                    = var.vcn_name != ""
  is_atp_db                       = var.is_atp_db
  is_oci_db                       = var.is_oci_db
  is_vcn_peering                  = local.has_existing_vcn && local.has_vcn_name && local.is_oci_db
  both_vcn_param_non_ocidb        = !local.is_oci_db ? local.has_existing_vcn && local.has_vcn_name : false
  invalid_use_of_existing_subnets = (local.has_wls_subnet_id || local.has_lb_backend_subnet_id || local.has_lb_frontend_subnet_id) && local.is_vcn_peering
  invalid_use_of_private_subnet   = var.assign_public_ip == "false" && local.is_vcn_peering
  has_wls_subnet_id               = var.wls_subnet_id != ""
  has_lb_backend_subnet_id        = var.lb_subnet_2_id != ""
  has_lb_frontend_subnet_id       = var.lb_subnet_1_id != ""
  has_mgmt_subnet_id              = var.bastion_subnet_id != ""
  missing_vcn_id                  = var.existing_vcn_id == "" && (local.has_wls_subnet_id || local.has_lb_backend_subnet_id || local.has_lb_frontend_subnet_id || local.has_mgmt_subnet_id)

  #existing subnets
  # If load balancer selected, check LB and WLS have existing subnet IDs specified else, if load balancer is not selected, check if WLS is using existing subnet id
  has_all_existing_subnets = var.add_load_balancer && local.has_wls_subnet_id && local.has_lb_backend_subnet_id && local.has_lb_frontend_subnet_id || !var.add_load_balancer && local.has_wls_subnet_id
  has_all_new_subnets      = var.add_load_balancer && !local.has_wls_subnet_id && !local.has_lb_backend_subnet_id && !local.has_lb_frontend_subnet_id || !var.add_load_balancer && !local.has_wls_subnet_id
  is_subnet_condition      = !local.has_all_existing_subnets || local.has_all_new_subnets
  missing_existing_subnets = var.assign_public_ip == "true" ? local.is_subnet_condition : false

  #existing private subnet
  has_all_existing_private_subnets = var.add_load_balancer && local.has_wls_subnet_id && local.has_lb_backend_subnet_id && local.has_lb_frontend_subnet_id && local.has_mgmt_subnet_id || !var.add_load_balancer && local.has_wls_subnet_id && local.has_mgmt_subnet_id
  has_all_new_private_subnets      = var.add_load_balancer && !local.has_wls_subnet_id && !local.has_lb_backend_subnet_id && !local.has_lb_frontend_subnet_id && local.has_mgmt_subnet_id || !var.add_load_balancer && !local.has_wls_subnet_id && local.has_mgmt_subnet_id
  is_private_subnet_condition      = !local.has_all_existing_private_regional_subnets || local.has_all_new_private_regional_subnets
  missing_existing_private_subnets = var.assign_public_ip == "false" ? local.is_private_subnet_condition : false

  #existing regional validation
  has_all_existing_regional_subnets = var.add_load_balancer && local.has_wls_subnet_id && local.has_lb_frontend_subnet_id || !var.add_load_balancer && local.has_wls_subnet_id
  has_all_new_regional_subnets      = var.add_load_balancer && !local.has_wls_subnet_id && !local.has_lb_frontend_subnet_id || !var.add_load_balancer && !local.has_wls_subnet_id
  is_regional_subnet_condition      = !local.has_all_existing_regional_subnets || local.has_all_new_regional_subnets
  missing_existing_regional_subnets = var.use_regional_subnet == "true" ? local.is_regional_subnet_condition : false

  #existing private regional validation
  has_all_existing_private_regional_subnets = var.add_load_balancer && local.has_wls_subnet_id && local.has_lb_frontend_subnet_id && local.has_mgmt_subnet_id || !var.add_load_balancer && local.has_wls_subnet_id && local.has_mgmt_subnet_id
  has_all_new_private_regional_subnets      = var.add_load_balancer && !local.has_wls_subnet_id && !local.has_lb_frontend_subnet_id && !local.has_mgmt_subnet_id || !var.add_load_balancer && !local.has_wls_subnet_id && !local.has_mgmt_subnet_id
  is_private_regional_subnet_condition      = !local.has_all_existing_private_regional_subnets || local.has_all_new_private_regional_subnets
  missing_existing_private_regional_subnets = var.assign_public_ip == "false" ? local.is_private_regional_subnet_condition : false

  missing_wls_dns_subnet_cidr = local.is_vcn_peering && var.wls_dns_subnet_cidr == ""

  # wls admin user validation
  invalid_wls_admin_user = replace(var.wls_admin_user, "/^[a-zA-Z][a-zA-Z0-9]{7,127}/", "0")

  #validate WLS Admin Password
  wlsAdminPassword = var.use_kms_decryption == "false" ? var.wls_admin_password : "dummyValue1"
  invalid_wls_admin_password = replace(
    local.wlsAdminPassword,
    "/^[a-zA-Z][a-zA-Z0-9$#_]{7,29}/",
    "0",
  )
  is_invalid_wls_admin_password = local.invalid_wls_admin_password != "0"
  missing_number_wls_admin_password    = replace(var.wls_admin_password, "/^.*[0-9].*/", "0")

  #KMS validation
  has_kms_endpoint             = var.kms_service_endpoint == ""
  missing_kms_service_endpoint = var.use_kms_decryption == "true" ? local.has_kms_endpoint : false
  has_kms_key_id               = var.kms_key_id == ""
  missing_kms_key_id           = var.use_kms_decryption == "true" ? local.has_kms_key_id : false

  #tag validations

  #special chars string denotes empty values for tags for validation purposes
  #otherwise zipmap function main.tf fails first for empty strings before validators executed
  defined_tag        = var.defined_tag == "~!@#$%^&*()" ? "" : var.defined_tag
  defined_tag_value  = var.defined_tag_value == "~!@#$%^&*()" ? "" : var.defined_tag_value
  freeform_tag       = var.freeform_tag == "~!@#$%^&*()" ? "" : var.freeform_tag
  freeform_tag_value = var.freeform_tag_value == "~!@#$%^&*()" ? "" : var.freeform_tag_value

  invalid_defined_tag = local.defined_tag == "" || length(split(".", local.defined_tag)) == 2 ? false : true

  check_defined_tag = var.defined_tag == "" ? false : local.invalid_defined_tag

  has_defined_tag_key   = local.defined_tag == "" ? false : true
  has_defined_tag_value = local.defined_tag_value == "" ? false : true

  has_freeform_tag_key   = local.freeform_tag == "" ? false : true
  has_freeform_tag_value = local.freeform_tag_value == "" ? false : true

  missing_defined_tag_key   = local.has_defined_tag_value && !local.has_defined_tag_key
  missing_defined_tag_value = !local.has_defined_tag_value && local.has_defined_tag_key

  missing_freeform_tag_key   = local.has_freeform_tag_value && !local.has_freeform_tag_key
  missing_freeform_tag_value = !local.has_freeform_tag_value && local.has_freeform_tag_key

  #tag length validation
  invalid_length_defined_tag       = length(local.defined_tag) > 100
  invalid_length_defined_tag_value = length(local.defined_tag_value) > 256

  invalid_length_freeform_tag       = length(local.freeform_tag) > 100
  invalid_length_freeform_tag_value = length(local.freeform_tag_value) > 256

  service_name_prefix_msg      = "SOAC-ERROR: The [service_name] min length is 1 and max length is 15 characters. It can only contain letters or numbers and must begin with a letter. Invalid service name: [${var.original_service_name}]"
  validate_service_name_prefix = local.invalid_service_name_prefix ? local.validators_msg_map[local.service_name_prefix_msg] : null

  wls_dns_subnet_cidr_msg              = "SOAC-ERROR: The value for [wls_dns_subnet_cidr] is required when using VCN peering [both existing_vcn_id and wls_vcn_name provided] with OCI DB."
  validate_missing_wls_dns_subnet_cidr = local.missing_wls_dns_subnet_cidr ? local.validators_msg_map[local.wls_dns_subnet_cidr_msg] : null

  both_vcn_param_non_ocidb_msg      = "SOAC-ERROR: Both existing_vcn_id and wls_vcn_name cannot be provided if not provisioning with OCI DB."
  validate_both_vcn_param_non_ocidb = local.both_vcn_param_non_ocidb ? local.validators_msg_map[local.both_vcn_param_non_ocidb_msg] : null

  invalid_db_not_allowed_msg = "SOAC-ERROR: Weblogic 11g version is not supported with ATP DB and Non-JRF provisioning."
  invalid_db_not_allowed     = local.invalid_atp_db_not_allowed ? local.validators_msg_map[local.invalid_db_not_allowed_msg] : null

  missing_vcn_msg     = "SOAC-ERROR: Atleast one of existing_vcn_id or vcn_name must be provided. Both can only be provided when provisioning with OCI DB in peered VCNs."
  validate_vcn_params = local.missing_vcn ? local.validators_msg_map[local.missing_vcn_msg] : null

  invalid_log_level_msg = "SOAC-ERROR: The value for log_level=[${var.log_level}] is not valid. The permissible values are [DEBUG, INFO, WARNING, ERROR, CRITICAL]."
  validate_log_level    = local.invalid_log_level ? local.validators_msg_map[local.invalid_log_level_msg] : null

  invalid_vm_count_msg    = "SOAC-ERROR: The value for wls_node_count=[${var.numVMInstances}] is not valid. The permissible values are [1-8]."
  validate_numVMInstances = local.invalid_vm_count ? local.validators_msg_map[local.invalid_vm_count_msg] : null

  invalid_lb_availability_domain_indexes_msg = "SOAC-ERROR: The value for lb_subnet_1_availability_domain_name=[${var.lb_availability_domain_name1}] and lb_subnet_2_availability_domain_name=[${var.lb_availability_domain_name2}] cannot be same."
  validate_lb_availability_domain_indexes    = local.invalid_lb_availability_domain_indexes ? local.validators_msg_map[local.invalid_lb_availability_domain_indexes_msg] : null

  invalid_wls_edition_msg = "SOAC-ERROR: The value for wls_edition=[${var.wls_edition}] is not valid. The permissible values are [ EE, SUITE ]."
  validate_wls_edition    = local.invalid_wls_edition ? local.validators_msg_map[local.invalid_wls_edition_msg] : null

  invalid_wls_version_msg = "SOAC-ERROR: The value for wls_version=[${var.wls_version}] is not valid. The permissible values are [ 11.1.1.7, 12.2.1.3, 12.2.1.4 ]."
  validate_wls_version    = local.invalid_wls_version ? local.validators_msg_map[local.invalid_wls_version_msg] : null

  invalid_wls_console_port_msg = "SOAC-ERROR: The value for wls_console_port=[${var.wls_console_port}] is not valid. The value has to be greater than 0."
  validate_wls_console_port    = local.invalid_wls_console_port ? local.validators_msg_map[local.invalid_wls_console_port_msg] : null

  invalid_wls_console_ssl_port_msg = "SOAC-ERROR: The value for wls_console_ssl_port=[${var.wls_console_ssl_port}] is not valid. The value has to be greater than 0."
  validate_wls_console_ssl_port    = local.invalid_wls_console_ssl_port ? local.validators_msg_map[local.invalid_wls_console_ssl_port_msg] : null

  invalid_wls_extern_admin_port_msg = "SOAC-ERROR: The value for wls_extern_admin_port=[${var.wls_extern_admin_port}] is not valid. The value has to be greater than 0."
  validate_wls_extern_admin_port    = local.invalid_wls_extern_admin_port ? local.validators_msg_map[local.invalid_wls_extern_admin_port_msg] : null

  invalid_wls_extern_ssl_admin_port_msg = "SOAC-ERROR: The value for wls_extern_ssl_admin_port=[${var.wls_extern_ssl_admin_port}] is not valid. The value has to be greater than 0."
  validate_wls_extern_ssl_admin_port    = local.invalid_wls_extern_ssl_admin_port ? local.validators_msg_map[local.invalid_wls_extern_ssl_admin_port_msg] : null

  invalid_wls_nm_port_msg = "SOAC-ERROR: The value for wls_nm_port=[${var.wls_nm_port}] is not valid. The value has to be greater than 0."
  validate_wls_nm_port    = local.invalid_wls_nm_port ? local.validators_msg_map[local.invalid_wls_nm_port_msg] : null

  invalid_wls_ms_port_msg = "SOAC-ERROR: The value for wls_ms_port=[${var.wls_ms_port}] is not valid. The value has to be greater than 0."
  validate_wls_ms_port    = local.invalid_wls_ms_port ? local.validators_msg_map[local.invalid_wls_ms_port_msg] : null

  invalid_wls_cluster_mc_port_msg = "SOAC-ERROR: The value for wls_cluster_mc_port=[${var.wls_cluster_mc_port}] is not valid. The value has to be greater than 0."
  validate_wls_cluster_mc_port    = local.invalid_wls_cluster_mc_port ? local.validators_msg_map[local.invalid_wls_cluster_mc_port_msg] : null

  missing_wls_subnet_cidr_msg      = "SOAC-ERROR: The value for wls_subnet_cidr is required if existing virtual cloud network is used."
  validate_missing_wls_subnet_cidr = local.missing_wls_subnet_cidr ? local.validators_msg_map[local.missing_wls_subnet_cidr_msg] : null

  missing_lb_subnet_1_cidr_msg      = "SOAC-ERROR: The value for lb_subnet_1_cidr is required if existing virtual cloud network is used and LB is added."
  validate_missing_lb_subnet_1_cidr = local.missing_lb_subnet_1_cidr ? local.validators_msg_map[local.missing_lb_subnet_1_cidr_msg] : null

  missing_mgmt_backend_subnet_cidr_msg      = "SOAC-ERROR: The value for bastion_subnet_cidr is required with existing virtual cloud network and weblogic in private subnet."
  validate_missing_mgmt_backend_subnet_cidr = local.missing_mgmt_backend_subnet_cidr ? local.validators_msg_map[local.missing_mgmt_backend_subnet_cidr_msg] : null

  missing_vcn_id_msg      = "SOAC-ERROR: The value for existing_vcn_id is required if existing subnets are used for provisioning."
  validate_missing_vcn_id = local.missing_vcn_id ? local.validators_msg_map[local.missing_vcn_id_msg] : null

  invalid_multiple_infra_dbs_msg      = "SOAC-ERROR: Both OCI and ATP database parameters are provided. Only one infra database is required."
  validate_invalid_multiple_infra_dbs = local.invalid_multiple_infra_dbs ? local.validators_msg_map[local.invalid_multiple_infra_dbs_msg] : null

  invalid_use_of_existing_subnets_msg      = "SOAC-ERROR: VCN peering cannot be done using existing subnets. The variables wls_vcn_name and existing_vcn_id cannot be used with existing subnet ids."
  validate_invalid_use_of_existing_subnets = local.invalid_use_of_existing_subnets ? local.validators_msg_map[local.invalid_use_of_existing_subnets_msg] : null

  invalid_use_of_private_subnet_msg      = "SOAC-ERROR: VCN peering cannot be done using private subnets."
  validate_invalid_use_of_private_subnet = local.invalid_use_of_private_subnet ? local.validators_msg_map[local.invalid_use_of_private_subnet_msg] : null

  missing_existing_subnets_msg      = "SOAC-ERROR: Provide all required existing subnet id if one of the existing subnets is provided[ lb_subnet_1_id, lb_subnet_2_id, wls_subnet_id ]."
  validate_missing_existing_subnets = var.use_regional_subnet == "false" && local.missing_existing_subnets ? local.validators_msg_map[local.missing_existing_subnets_msg] : null

  missing_existing_private_subnets_msg      = "SOAC-ERROR: Provide all required existing subnet ids if one of the existing subnets is provided [ lb_subnet_1_id, lb_subnet_2_id, wls_subnet_id, bastion_subnet_id ]."
  validate_missing_existing_private_subnets = var.use_regional_subnet == "false" && local.missing_existing_private_subnets ? local.validators_msg_map[local.missing_existing_private_subnets_msg] : null

  missing_existing_regional_subnets_msg      = "SOAC-ERROR: Provide all required existing subnet id if one of the existing subnets is provided[ lb_subnet_1_id, wls_subnet_id ]."
  validate_missing_existing_regional_subnets = var.use_regional_subnet == "true" && local.missing_existing_regional_subnets ? local.validators_msg_map[local.missing_existing_regional_subnets_msg] : null

  missing_existing_private_regional_subnets_msg      = "SOAC-ERROR: Provide all required existing subnet ids if one of the existing subnets is provided [ lb_subnet_1_id,  wls_subnet_id, bastion_subnet_id ]."
  validate_missing_existing_private_regional_subnets = var.use_regional_subnet == "true" && local.missing_existing_private_regional_subnets ? local.validators_msg_map[local.missing_existing_private_regional_subnets_msg] : null

  missing_number_wls_admin_password_msg      = "SOAC-ERROR: WebLogic Administrator password provided should contain at least one number, and optionally, any number of the special characters ($ # _).For example, Ach1z0#d"
  validate_wls_admin_password_for_one_number = local.missing_number_wls_admin_password != "0" ? local.validators_msg_map[local.missing_number_wls_admin_password_msg] : null

  is_invalid_wls_admin_password_msg = "SOAC-ERROR: WebLogic Administrator password provided should start with a letter, is between 8 and 30 characters long, contain at least one number, and, optionally, any number of the special characters ($ # _)"
  validate_wls_admin_password_length       = local.is_invalid_wls_admin_password ? local.validators_msg_map[local.is_invalid_wls_admin_password_msg] : null

  invalid_wls_admin_user_msg      = "SOAC-ERROR: WebLogic Administrator admin user provided should be alphanumeric and length should be between 8 and 128 characters."
  validate_invalid_wls_admin_user = local.invalid_wls_admin_user != "0" ? local.validators_msg_map[local.invalid_wls_admin_user_msg] : null

  missing_kms_service_endpoint_msg      = "SOAC-ERROR: The value for KMS service endpoint [ kms_service_endpoint ] is required."
  validate_missing_kms_service_endpoint = local.missing_kms_service_endpoint ? local.validators_msg_map[local.missing_kms_service_endpoint_msg] : null

  missing_kms_key_id_msg      = "SOAC-ERROR: The value for KMS key id [ kms_key_id ] is required."
  validate_missing_kms_key_id = local.missing_kms_key_id ? local.validators_msg_map[local.missing_kms_key_id_msg] : null

  duplicate_wls_subnet_cidr_msg      = "SOAC-ERROR: Weblogic subnet CIDR has to be unique value."
  validate_duplicate_wls_subnet_cidr = local.check_duplicate_wls_subnet_cidr ? local.validators_msg_map[local.duplicate_wls_subnet_cidr_msg] : null

  duplicate_lb1_subnet_cidr_msg      = "SOAC-ERROR: Load balancer subnet 1 CIDR has to be unique value."
  validate_duplicate_lb1_subnet_cidr = local.check_duplicate_lb1_subnet_cidr ? local.validators_msg_map[local.duplicate_lb1_subnet_cidr_msg] : null

  duplicate_lb2_subnet_cidr_msg      = "SOAC-ERROR: Load balancer subnet 2 CIDR has to be unique value."
  validate_duplicate_lb2_subnet_cidr = local.check_duplicate_lb2_subnet_cidr ? local.validators_msg_map[local.duplicate_lb2_subnet_cidr_msg] : null

  invalid_defined_tag_msg      = "SOAC-ERROR: The defined tag name is not valid [${var.defined_tag}]. The defined tag name should of the format <tagnamespace>.<tagname>."
  validate_invalid_defined_tag = local.check_defined_tag ? local.validators_msg_map[local.invalid_defined_tag_msg] : null

  missing_defined_tag_key_msg      = "SOAC-ERROR: The value for defined tag key [ defined_tag ] is required."
  validate_missing_defined_tag_key = local.missing_defined_tag_key ? local.validators_msg_map[local.missing_defined_tag_key_msg] : null

  missing_defined_tag_value_msg      = "SOAC-ERROR: The value for defined tag key value [ defined_tag_value ] is required."
  validate_missing_defined_tag_value = local.missing_defined_tag_value ? local.validators_msg_map[local.missing_defined_tag_value_msg] : null

  missing_freeform_tag_key_msg      = "SOAC-ERROR: The value for free-form tag key [ free_form_tag ] is required."
  validate_missing_freeform_tag_key = local.missing_freeform_tag_key ? local.validators_msg_map[local.missing_freeform_tag_key_msg] : null

  missing_freeform_tag_value_msg      = "SOAC-ERROR: The value for free-form tag key value [ free_form_tag_value ] is required."
  validate_missing_freeform_tag_value = local.missing_freeform_tag_value ? local.validators_msg_map[local.missing_freeform_tag_value_msg] : null

  invalid_length_defined_tag_msg = "SOAC-ERROR: The length of the defined tag is between 1-100. Invalid tag name: [${local.defined_tag}]."
  validate_defined_tag_length    = local.invalid_length_defined_tag ? local.validators_msg_map[local.invalid_length_defined_tag_msg] : null

  invalid_length_defined_tag_value_msg = "SOAC-ERROR: The length of the defined tag value is between 1-256. Invalid tag value: [${local.defined_tag_value}]."
  validate_defined_tag_value_length    = local.invalid_length_defined_tag_value ? local.validators_msg_map[local.invalid_length_defined_tag_value_msg] : null

  invalid_length_freeform_tag_msg = "SOAC-ERROR: The length of the free-form tag is between 1-100.  Invalid tag : [${local.freeform_tag}]."
  validate_freeform_tag_length    = local.invalid_length_freeform_tag ? local.validators_msg_map[local.invalid_length_freeform_tag_msg] : null

  invalid_length_freeform_tag_value_msg = "SOAC-ERROR: The length of the free-form  tag value is between 1-256.  Invalid tag value: [${local.freeform_tag_value}]."
  validate_freeform_tag_value_length    = local.invalid_length_freeform_tag_value ? local.validators_msg_map[local.invalid_length_freeform_tag_value_msg] : null

  invalid_mft_atp_selected_msg = "SOAC-ERROR: ATP Database is not supported for [${var.topology}]."
  validate_mft_atp_selected    = local.invalid_mft_atp_selected ? local.validators_msg_map[local.invalid_mft_atp_selected_msg] : null

  invalid_bam_atp_selected_msg = "SOAC-ERROR: ATP Database is not supported for [${var.topology}]."
  validate_bam_atp_selected    = local.invalid_bam_atp_selected ? local.validators_msg_map[local.invalid_bam_atp_selected_msg] : null

  #invalid_bam_multinode_selected_msg = "SOAC-ERROR: BAM Cluster Multi-Node is not supported. Invalid wls_node_count=[${var.numVMInstances}]."
  #validate_bam_multinode_selected    = local.invalid_bam_multinode_selected ? local.validators_msg_map[local.invalid_bam_multinode_selected_msg] : null
}

