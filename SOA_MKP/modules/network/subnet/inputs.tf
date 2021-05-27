variable "compartment_ocid" {
  type = string
}

variable "subnet_compartment_id" {
  type = string
}

variable "service_name_prefix" {
  type = string
}

variable "dns_label" {
  type = string
}

variable "availability_domain" {
  type = string
}

variable "tenancy_ocid" {
  type = string
}

variable "vcn_id" {
  type = string
}

variable "subnetCount" {
  default = "1"
}

variable "use_existing_bastion" {
  default = "false"
}

variable "security_list_id" {
  type = list(string)
}

variable "dhcp_options_id" {
  type = string
}

variable "route_table_id" {
  type = string
}

variable "cidr_block" {
  type = string
}

variable "subnet_name" {
  default = "wls-subnet"
}

variable "add_load_balancer" {
  default = "false"
}

variable "is_vcn_peered" {
  default = "false"
}

variable "prohibit_public_ip" {
  default = "false"
}

//if existing subnet is used
variable "subnet_id" {
  default = ""
}

variable "use_existing_subnets" {
  default = "false"
}

variable "use_regional_subnet" {
  default = "false"
}

variable "defined_tags" {
  type    = map(string)
  default = {}
}

variable "freeform_tags" {
  type    = map(string)
  default = {}
}

