/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */

resource "null_resource" "atp_provisioning" {
  count = (var.is_atp_db && !var.use_kms_decryption)?1:0

  // Upload wallet file.
  // Upload wallet file.
  provisioner "file" {
    source      = "${path.module}/atp_wallet.zip"
    destination = "/tmp/atp_wallet.zip"

    connection {
      agent       = false
      timeout     = "30m"
      host        = var.host_ips[0]
      user        = "opc"
      private_key = var.ssh_private_key

      bastion_user        = "opc"
      bastion_private_key = var.bastion_host_private_key
      bastion_host        = var.bastion_host
    }
  }
}

