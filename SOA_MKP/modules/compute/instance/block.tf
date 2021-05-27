resource "oci_core_volume" "wls-domain-block" {
  count               = var.numVMInstances * var.num_volumes
  availability_domain = var.use_regional_subnet?local.ad_names[count.index % length(local.ad_names)]:var.availability_domain
  compartment_id      = var.compartment_ocid
  display_name        = "${var.compute_name_prefix}-block-${count.index}"
  size_in_gbs         = var.volume_size
  defined_tags        = var.defined_tags
  freeform_tags       = var.freeform_tags
}

resource "oci_core_volume_attachment" "wls-block-attach" {
  count           = var.numVMInstances * var.num_volumes
  display_name    = var.data_volume_map["display_name"]
  attachment_type = "iscsi"
  instance_id     = oci_core_instance.wls-compute-instance[count.index / var.num_volumes].id
  volume_id       = oci_core_volume.wls-domain-block[count.index].id
}

