variable "tenancy_ocid" {
}

variable "compartment_ocid" {
}

variable "availability_domain" {
}

variable "subnet_ocid" {
default = ""
}


//WLS subnet id
variable "wls_subnet_id" {}

variable "use_regional_subnet" {
  default = "false"
}

variable "ssh_public_key" {
  type = string
}

variable "compute_name_prefix" {
  default = "soa-instance"
}

variable "vnic_prefix" {
  default = "soa"
}

variable "instance_image_ocid" {
}

# Defines the number of instances to deploy
variable "numVMInstances" {
  type    = string
  default = "2"
}

# WLS Related variables
variable "wls_admin_user" {
  type = string
}

variable "wls_domain_name" {
  type = string
}

variable "wls_admin_server_name" {
  type = string
}

variable "wls_admin_password" {
  type = string
}

variable "use_custom_nm_password" {
}

variable "wls_nm_password" {
  type = string
}

variable "bootStrapFile" {
  type    = string
  default = "./modules/compute/instance/userdata/bootstrap"
}

variable "instance_shape" {
  type = string
}

variable "region" {
  type = string
}

variable "wls_extern_admin_port" {
  default = "9071"
}

variable "wls_extern_ssl_admin_port" {
  default = "9072"
}

variable "provisioning_timeout_mins" {
  default = 30
}

variable "wls_admin_server_wait_timeout_mins" {
  default = 30
}

variable "wls_console_port" {
  default = "7001"
}

variable "wls_console_ssl_port" {
  default = "7002"
}

variable "wls_nm_port" {
  default = "5556"
}

variable "wls_provisioning_timeout" {
  default = "10"
}

variable "wls_cluster_name" {
  default = "soaoci_cluster"
}

variable "wls_ms_port" {
  default = "7003"
}

variable "wls_ms_ssl_port" {
  default = "7004"
}

variable "wls_ms_server_name" {
  default = "soaoci_server_"
}

variable "wls_cluster_mc_port" {
  default = "5555"
}

variable "wls_machine_name" {
  default = "soaoci_machine_"
}

/*
********************
Common DB Config
********************
*/
variable "db_password" {
  default = ""
}

variable "db_user" {
  default = ""
}

/*
********************
OCI DB Config
********************
*/
// Provide DB node count - for node count > 1, WLS AGL datasource will be created

variable "ocidb_compartment_id" {
}

variable "ocidb_dbsystem_id" {
}

variable "ocidb_database_id" {
}

variable "ocidb_pdb_service_name" {
}

variable "ocidb_db_port" {
}

/*
********************
ATP DB Config
********************
*/

variable "atp_db_id" {
}

variable "atp_db_level" {
}

variable "rcu_component_list" {
  default = "MDS,WLS,STB,IAU_APPEND,IAU_VIEWER,UCSUMS,IAU,OPSS,SOAINFRA"
}

variable "wls_edition" {
  default = "EE"
}

// Required params for bootstrap.py (part of image)
variable "mode" {
}

variable "tf_script_version" {
}

variable "wls_version" {
}

variable "topology" {
}

variable "use_schema_partitioning" {
}

variable "use_custom_schema_prefix" {
}

variable "rcu_schema_prefix" {
}

variable "use_custom_schema_password" {
}

variable "creds_path" {
  default = "/opt/.creds"
}

/**
 * Defines the mapping between wls_version and corresponding FMW zip.
 */
variable "wls_version_to_fmw_map" {
  type = map(string)

  default = {
    "12.2.1.4" = "/u01/zips/jcs/FMW/12.2.1.4.0/fmiddleware.zip"
    "12.2.1.3" = "/u01/zips/jcs/FMW/12.2.1.3.0/fmiddleware.zip"
    "11.1.1.7" = "/u01/zips/jcs/FMW/11.1.1.7.0/fmiddleware.zip"
  }
}

/**
 * Defines the mapping between wls_version and corresponding JDK zip.
 */
variable "wls_version_to_jdk_map" {
  type = map(string)

  default = {
    "12.2.1.4" = "/u01/zips/jcs/JDK8.0/jdk.zip"
    "12.2.1.3" = "/u01/zips/jcs/JDK8.0/jdk.zip"
    "11.1.1.7" = "/u01/zips/jcs/JDK7.0/jdk.zip"
  }
}

variable "vmscripts_path" {
  default = "/u01/zips/TF/wlsoci-vmscripts.zip"
}

variable "wls_version_to_rcu_component_list_map" {
  type = map(string)

  default = {
    "12.2.1.4" = "MDS,WLS,STB,IAU_APPEND,IAU_VIEWER,UCSUMS,IAU,OPSS,SOAINFRA"
    "12.2.1.3" = "MDS,WLS,STB,IAU_APPEND,IAU_VIEWER,UCSUMS,IAU,OPSS,SOAINFRA"
    "11.1.1.7" = "IAU,IAUOES,MDS,OPSS"
  }
}

variable "log_level" {
  default = "INFO"
}

variable "rebootFile" {
  type    = string
  default = "./modules/compute/instance/userdata/reboot"
}

variable "num_volumes" {
  type    = string
  default = "1"
}

variable "volume_size" {
  default = "50"
}

variable "data_volume_map" {
  type = map(string)

  default = {
    "data_volume_mount_point" = "/u01/data"
    "display_name"            = "data"
    "device"                  = "/dev/sdb"
  }
}

variable "deploy_sample_app" {
  default = "true"
}

variable "volume_info_file" {
  default = "/tmp/volumeInfo.json"
}

variable "domain_dir" {
  default = "/u01/data/domains"
}

variable "logs_dir" {
  default = "/u01/logs"
}

variable "assign_public_ip" {
}

variable "opc_key" {
  type = map(string)
}

variable "oracle_key" {
  type = map(string)
}

variable "status_check_timeout_duration_secs" {
  default = "2700"
}

variable "is_vcn_peered" {
}

variable "wls_dns_vm_ip" {
}

variable "use_kms_decryption" {
}

variable "lb_use_https" {
}

/*
********************
IDCS Support
********************
*/
variable "is_idcs_selected" {
}

variable "idcs_host" {
}

variable "idcs_port" {
}

variable "idcs_tenant" {
}

variable "idcs_client_id" {
}

variable "idcs_cloudgate_port" {
}

variable "idcs_app_prefix" {
}

variable "idcs_conf_app_info_file" {
  default = "/tmp/idcs_conf_app_info.txt"
}

variable "idcs_ent_app_info_file" {
  default = "/tmp/idcs_ent_app_info.txt"
}

variable "idcs_cloudgate_info_file" {
  default = "/tmp/idcs_cloudgate_info.txt"
}

variable "idcs_cloudgate_config_file" {
  default = "/u01/data/cloudgate_config/appgateway-env"
}

variable "idcs_cloudgate_docker_image_tar" {
  default = "/u01/zips/jcs/app_gateway_docker/19.2.1/app-gateway-docker-image.tar.gz"
}

variable "idcs_cloudgate_docker_image_version" {
  default = "19.2.1-1908290158"
}

variable "idcs_cloudgate_docker_image_name" {
  default = "opc-delivery.docker.oraclecorp.com/idcs/appgateway"
}

variable "lbip_filepath" {
  default = "/tmp/lb_public_ip.txt"
}

variable "is_idcs_internal" {
  default = "false"
}

variable "is_idcs_untrusted" {
  default = "false"
}

variable "idcs_ip" {
  default = ""
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

