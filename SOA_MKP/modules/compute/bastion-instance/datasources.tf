# Gets a list of Availability Domains in the tenancy
data "oci_identity_availability_domains" "ADs" {
  compartment_id = var.tenancy_ocid
}

data "template_file" "bastion_key_script" {
  template = file(
    "./modules/compute/bastion-instance/templates/bastion-keys.tpl",
  )

  vars = {
    pubKey = var.opc_key["public_key_openssh"]
  }
}

# get latest CentOS 7 image OCID 
data "oci_core_images" "centos7" {
  compartment_id   = var.compartment_ocid
  operating_system = "CentOS"

  # filter restricts to version 7
  filter {
    name   = "operating_system_version"
    values = ["7(\\.\\d)?"]
    regex  = "true"
  }
}

