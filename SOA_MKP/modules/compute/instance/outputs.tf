# Output the private and public IPs of the instance
output "InstancePrivateIPs" {
  value = oci_core_instance.wls-compute-instance.*.private_ip
}

output "InstancePublicIPs" {
  value = oci_core_instance.wls-compute-instance.*.public_ip
}

output "PrivateAdminIP" {
  value = oci_core_instance.wls-compute-instance[0].private_ip
}

output "PublicAdminIP" {
  value = oci_core_instance.wls-compute-instance[0].public_ip
}

output "InstanceOcids" {
  value = oci_core_instance.wls-compute-instance.*.id
}

output "DataVolumeOcids" {
  value = oci_core_volume.wls-domain-block.*.id
}

output "display_names" {
  value = oci_core_instance.wls-compute-instance.*.display_name
}

output "VolumeAttachmentInfo" {
  value = formatlist(
    " { \"instance_id\":\"%s\", \"iqn\":\"%s\", \"port\":\"%s\", \"ipv4\":\"%s\" }",
    oci_core_volume_attachment.wls-block-attach.*.instance_id,
    oci_core_volume_attachment.wls-block-attach.*.iqn,
    oci_core_volume_attachment.wls-block-attach.*.port,
    oci_core_volume_attachment.wls-block-attach.*.ipv4,
  )
}

output "WlsVersion" {
  value = var.wls_version
}

