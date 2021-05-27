/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */

data "oci_database_autonomous_database" "atp_db" {
  count = (var.is_atp_db && !var.use_kms_decryption)?1:0

  #Required
  autonomous_database_id = var.atp_db_id
}

data "oci_database_autonomous_database_wallet" "atp_wallet" {
  count = (var.is_atp_db && !var.use_kms_decryption)?1:0

  #Required
  autonomous_database_id = var.atp_db_id
  base64_encode_content  = "true"
  generate_type          = ""
  password = md5(
    format(
      "%s:%s",
      var.atp_db_id,
      data.oci_database_autonomous_database.atp_db[0].db_name,
    ),
  )
}

resource "local_file" "autonomous_database_wallet_file" {
  count = (var.is_atp_db && !var.use_kms_decryption)?1:0

  content_base64  = data.oci_database_autonomous_database_wallet.atp_wallet[0].content
  filename = "${path.module}/atp_wallet.zip"
}

