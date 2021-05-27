
resource "oci_core_instance" "wls-bastion-instance" {
  count = !var.use_existing_bastion?var.instance_count:0

  //assumption: it is the same ad as wls
  availability_domain = var.availability_domain

  compartment_id = var.compartment_ocid
  display_name   = var.instance_name
  shape          = var.instance_shape

  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags

  create_vnic_details {
    subnet_id              = var.bastion_subnet_ocid
    skip_source_dest_check = true
    assign_public_ip       = true
  }

  metadata = {
    ssh_authorized_keys = var.ssh_public_key
    user_data           = data.template_cloudinit_config.bastion-config.rendered
  }

  source_details {
    source_type = "image"
    source_id   = data.oci_core_images.centos7.images[0].id
  }

  timeouts {
    create = "10m"
  }
}

