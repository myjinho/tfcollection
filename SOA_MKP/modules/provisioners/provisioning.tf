/*
 * Copyright (c) 2019 Oracle and/or its affiliates. All rights reserved.
 */
resource "null_resource" "provisioning_atp_nokms" {
  count = (var.is_atp_db && !var.use_kms_decryption)?var.numVMInstances:0

  //Adding explicit dependency on the other provisioners so this provisioner executes in the end.
  depends_on = [
    null_resource.atp_provisioning,
    null_resource.dev_mode_provisioning,
  ]

  triggers = {
    admin_ip = var.admin_ip
  }
  // Executing the check provisioning status as a short running task over SSH. There is a possibility that it fails
  // due to network issues but we wont be interferring with provisioning as it will continue in the background on the VM
  // only we will not be able to see the status or know when it completes.
  // Executing the check provisioning status as a short running task over SSH. There is a possibility that it fails
  // due to network issues but we wont be interferring with provisioning as it will continue in the background on the VM
  // only we will not be able to see the status or know when it completes.
  provisioner "remote-exec" {
    // Connection setup for all WLS instances
    // Connection setup for all WLS instances
    connection {
      agent       = false
      timeout     = "30m"
      host        = var.host_ips[count.index]
      user        = "opc"
      private_key = var.ssh_private_key

      bastion_user        = "opc"
      bastion_private_key = var.bastion_host_private_key
      bastion_host        = var.bastion_host
    }

    inline = [
      "echo ${jsonencode(var.volumeAttachmentInfo[count.index])} > /tmp/volumeInfo.json",
      "sudo su - oracle -c 'echo ${jsonencode(
        format(
          " { \"kms_service_endpoint\":\"%s\", \"kms_key_id\":\"%s\" }",
          var.kms_service_endpoint,
          var.kms_key_id,
        ),
      )} > /tmp/.kms'",
      "sudo su - oracle -c 'echo ${jsonencode(
        format(
          " { \"cred1\":\"%s\", \"cred2\":\"%s\", \"cred3\":\"%s\", \"cred4\":\"%s\", \"cred5\":\"%s\", \"cred6\":\"%s\"}",
          base64encode(var.wls_admin_password),
          base64encode(var.db_password),
          base64encode(
            md5(
              format(
                "%s:%s",
                var.atp_db_id,
                data.oci_database_autonomous_database.atp_db[0].db_name,
              ),
            ),
          ),
          base64encode(var.idcs_client_secret),
          base64encode(var.rcu_schema_password),
          base64encode(var.wls_nm_password),
        ),
      )} > ${var.creds_path}'",
      "sudo su - oracle -c 'mkdir -p /home/oracle/.ssh/'",
      "sudo su - oracle -c 'chmod 700 /home/oracle/.ssh'",
      "sudo su - oracle -c 'echo \"${var.oracle_key["private_key_pem"]}\" > /home/oracle/.ssh/id_rsa'",
      "sudo su - oracle -c 'chown -R oracle:oracle /home/oracle/.ssh/id_rsa'",
      "sudo su - oracle -c 'chmod 400 /home/oracle/.ssh/id_rsa'",
      "sudo su - oracle -c 'echo \"${var.oracle_key["public_key_openssh"]}\" >> /home/oracle/.ssh/authorized_keys'",
      "sudo su - oracle -c 'chown -R oracle:oracle /home/oracle/.ssh/authorized_keys'",
      "sudo su - oracle -c 'chmod 600 /home/oracle/.ssh/authorized_keys'",
      "[ 'true' == '${var.add_load_balancer}' ] && sudo su - oracle -c 'echo ${var.lb_public_ip[0]} > ${var.lbip_filepath}'",
      "sudo touch /u01/provStartMarker",
      "sudo sh /opt/scripts/check_status.sh",
    ]
  }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue

    // Connection setup for all WLS instances
    // Connection setup for all WLS instances
    connection {
      agent       = false
      timeout     = "30m"
      host        = self.triggers.admin_ip
      user        = "oracle"
      private_key = var.oracle_key["private_key_pem"]

      bastion_user        = "opc"
      bastion_private_key = var.bastion_host_private_key
      bastion_host        = var.bastion_host
    }

    inline = [
      "echo ${jsonencode(
        format(
          " { \"kms_service_endpoint\":\"%s\", \"kms_key_id\":\"%s\" }",
          var.kms_service_endpoint,
          var.kms_key_id,
        ),
      )} > /tmp/.kms",
      "echo ${jsonencode(
        format(
          " { \"cred1\":\"%s\", \"cred2\":\"%s\", \"cred3\":\"%s\", \"cred4\":\"%s\", \"cred5\":\"%s\", \"cred6\":\"%s\"}",
          base64encode(var.wls_admin_password),
          base64encode(var.db_password),
          base64encode(
            md5(
              format(
                "%s:%s",
                var.atp_db_id,
                data.oci_database_autonomous_database.atp_db[0].db_name,
              ),
            ),
          ),
          base64encode(var.idcs_client_secret),
          base64encode(var.rcu_schema_password),
          base64encode(var.wls_nm_password),
        ),
      )} > ${var.creds_path}",
      "sh /opt/scripts/deprov.sh ${count.index}",
    ]
  }
}

resource "null_resource" "provisioning" {
  count = (var.use_kms_decryption || (!var.use_kms_decryption && !var.is_atp_db))?var.numVMInstances:0

  //Adding explicit dependency on the other provisioners so this provisioner executes in the end.
  depends_on = [
    null_resource.atp_provisioning,
    null_resource.dev_mode_provisioning,
  ]
  triggers = {
    admin_ip = var.admin_ip
  }
  // Executing the check provisioning status as a short running task over SSH. There is a possibility that it fails
  // due to network issues but we wont be interferring with provisioning as it will continue in the background on the VM
  // only we will not be able to see the status or know when it completes.
  // Executing the check provisioning status as a short running task over SSH. There is a possibility that it fails
  // due to network issues but we wont be interferring with provisioning as it will continue in the background on the VM
  // only we will not be able to see the status or know when it completes.
  provisioner "remote-exec" {
    // Connection setup for all WLS instances
    // Connection setup for all WLS instances
    connection {
      agent       = false
      timeout     = "30m"
      host        = var.host_ips[count.index]
      user        = "opc"
      private_key = var.ssh_private_key

      bastion_user        = "opc"
      bastion_private_key = var.bastion_host_private_key
      bastion_host        = var.bastion_host
    }

    inline = [
      "echo ${jsonencode(var.volumeAttachmentInfo[count.index])} > /tmp/volumeInfo.json",
      "sudo su - oracle -c 'echo ${jsonencode(
        format(
          " { \"kms_service_endpoint\":\"%s\", \"kms_key_id\":\"%s\" }",
          var.kms_service_endpoint,
          var.kms_key_id,
        ),
      )} > /tmp/.kms'",
      "sudo su - oracle -c 'echo ${jsonencode(
        format(
          " { \"cred1\":\"%s\", \"cred2\":\"%s\", \"cred3\":\"\", \"cred4\":\"%s\", \"cred5\":\"%s\", \"cred6\":\"%s\"}",
          base64encode(var.wls_admin_password),
          base64encode(var.db_password),
          base64encode(var.idcs_client_secret),
          base64encode(var.rcu_schema_password),
          base64encode(var.wls_nm_password),
        ),
      )} > ${var.creds_path}'",
      "sudo su - oracle -c 'mkdir -p /home/oracle/.ssh/'",
      "sudo su - oracle -c 'chmod 700 /home/oracle/.ssh'",
      "sudo su - oracle -c 'echo \"${var.oracle_key["private_key_pem"]}\" > /home/oracle/.ssh/id_rsa'",
      "sudo su - oracle -c 'chown -R oracle:oracle /home/oracle/.ssh/id_rsa'",
      "sudo su - oracle -c 'chmod 400 /home/oracle/.ssh/id_rsa'",
      "sudo su - oracle -c 'echo \"${var.oracle_key["public_key_openssh"]}\" >> /home/oracle/.ssh/authorized_keys'",
      "sudo su - oracle -c 'chown -R oracle:oracle /home/oracle/.ssh/authorized_keys'",
      "sudo su - oracle -c 'chmod 600 /home/oracle/.ssh/authorized_keys'",
      "[ 'true' == '${var.add_load_balancer}' ] && sudo su - oracle -c 'echo ${var.lb_public_ip[0]} > ${var.lbip_filepath}'",
      "sudo touch /u01/provStartMarker",
      "sudo sh /opt/scripts/check_status.sh",
    ]
  }

  provisioner "remote-exec" {
    when       = destroy
    on_failure = continue

    // Connection setup for all WLS instances
    // Connection setup for all WLS instances
    connection {
      agent       = false
      timeout     = "30m"
      host        = self.triggers.admin_ip
      user        = "oracle"
      private_key = var.oracle_key["private_key_pem"]

      bastion_user        = "opc"
      bastion_private_key = var.bastion_host_private_key
      bastion_host        = var.bastion_host
    }

    inline = [
      "echo ${jsonencode(
        format(
          " { \"kms_service_endpoint\":\"%s\", \"kms_key_id\":\"%s\" }",
          var.kms_service_endpoint,
          var.kms_key_id,
        ),
      )} > /tmp/.kms",
      "echo ${jsonencode(
        format(
          " { \"cred1\":\"%s\", \"cred2\":\"%s\", \"cred3\":\"\", \"cred4\":\"%s\", \"cred5\":\"%s\", \"cred6\":\"%s\"}",
          base64encode(var.wls_admin_password),
          base64encode(var.db_password),
          base64encode(var.idcs_client_secret),
          base64encode(var.rcu_schema_password),
          base64encode(var.wls_nm_password),
        ),
      )} > ${var.creds_path}",
      "sh /opt/scripts/deprov.sh ${count.index}",
    ]
  }
}

resource "null_resource" "status_check_atp_nokms" {
  count      = (var.is_atp_db && !var.use_kms_decryption)?var.numVMInstances:0
  depends_on = [null_resource.provisioning_atp_nokms]

  // Connection setup for all WLS instances
  // Connection setup for all WLS instances
  connection {
    agent       = false
    timeout     = "30m"
    host        = var.host_ips[count.index]
    user        = "opc"
    private_key = var.ssh_private_key

    bastion_user        = "opc"
    bastion_private_key = var.bastion_host_private_key
    bastion_host        = var.bastion_host
  }

  // Call check_status.sh 11 more times - if we add additional markers we must add an additional status check call here.
  // Also see - all_markers_list in check_provisioning_status.py for the list of all existing markers.
  // It is OK to call provisioning check more times than there are markers but we should at least call it as many times
  // as there are number of marker files created on VM.
  // Call check_status.sh 11 more times - if we add additional markers we must add an additional status check call here.
  // Also see - all_markers_list in check_provisioning_status.py for the list of all existing markers.
  // It is OK to call provisioning check more times than there are markers but we should at least call it as many times
  // as there are number of marker files created on VM.
  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }
}

resource "null_resource" "status_check" {
  count      = (var.use_kms_decryption || (!var.use_kms_decryption && !var.is_atp_db))?var.numVMInstances:0
  depends_on = [null_resource.provisioning]

  // Connection setup for all WLS instances
  // Connection setup for all WLS instances
  connection {
    agent       = false
    timeout     = "30m"
    host        = var.host_ips[count.index]
    user        = "opc"
    private_key = var.ssh_private_key

    bastion_user        = "opc"
    bastion_private_key = var.bastion_host_private_key
    bastion_host        = var.bastion_host
  }

  // Call check_status.sh 11 more times - if we add additional markers we must add an additional status check call here.
  // Also see - all_markers_list in check_provisioning_status.py for the list of all existing markers.
  // It is OK to call provisioning check more times than there are markers but we should at least call it as many times
  // as there are number of marker files created on VM.
  // Call check_status.sh 11 more times - if we add additional markers we must add an additional status check call here.
  // Also see - all_markers_list in check_provisioning_status.py for the list of all existing markers.
  // It is OK to call provisioning check more times than there are markers but we should at least call it as many times
  // as there are number of marker files created on VM.
  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su - oracle -c 'python /opt/scripts/check_provisioning_status.py'",
    ]
  }
}

resource "null_resource" "cleanup_atp_nokms" {
  count      = (var.is_atp_db && !var.use_kms_decryption)?var.numVMInstances:0
  depends_on = [null_resource.status_check_atp_nokms]

  // Connection setup for all WLS instances
  // Connection setup for all WLS instances
  connection {
    agent       = false
    timeout     = "30m"
    host        = var.host_ips[count.index]
    user        = "opc"
    private_key = var.ssh_private_key

    bastion_user        = "opc"
    bastion_private_key = var.bastion_host_private_key
    bastion_host        = var.bastion_host
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /opt/scripts/delete_keys.sh",
    ]
  }
}

resource "null_resource" "cleanup" {
  count      = (var.use_kms_decryption || (!var.use_kms_decryption && !var.is_atp_db))?var.numVMInstances:0
  depends_on = [null_resource.status_check]

  // Connection setup for all WLS instances
  // Connection setup for all WLS instances
  connection {
    agent       = false
    timeout     = "30m"
    host        = var.host_ips[count.index]
    user        = "opc"
    private_key = var.ssh_private_key

    bastion_user        = "opc"
    bastion_private_key = var.bastion_host_private_key
    bastion_host        = var.bastion_host
  }

  provisioner "remote-exec" {
    inline = [
      "sudo /opt/scripts/delete_keys.sh",
    ]
  }
}

#resource "null_resource" "cleanup_bastion_atp_nokms" {
#  count = "${var.assign_public_ip=="false" && (var.is_atp_db == "true" && var.use_kms_decryption == "false")?1:0}"
#  depends_on = ["null_resource.cleanup_atp_nokms"]
#
#
#
#  // Connection setup for all WLS instances
#  connection {
#    agent       = false
#    timeout     = "30m"
#    host        = "${var.bastion_host}"
#    user        = "opc"
#    private_key = "${var.bastion_host_private_key}"
#  }
#
#  provisioner "remote-exec" {
#    inline = [
#      "sudo cp /home/opc/.ssh/authorized_keys.bak /home/opc/.ssh/authorized_keys",
#      "rm -f /home/opc/.ssh/authorized_keys.bak",
#      "chown -R opc /home/opc/.ssh/authorized_keys"
#    ]
#  }
#}
#
#
#resource "null_resource" "cleanup_bastion" {
#  count = "${var.assign_public_ip=="false" && (var.use_kms_decryption == "true" || (var.use_kms_decryption == "false" && var.is_atp_db == "false"))?1:0}"
#  depends_on = ["null_resource.cleanup"]
#
#
#
#  // Connection setup for all WLS instances
#  connection {
#    agent       = false
#    timeout     = "30m"
#    host        = "${var.bastion_host}"
#    user        = "opc"
#    private_key = "${var.bastion_host_private_key}"
#  }
#
#  provisioner "remote-exec" {
#    inline = [
#      "sudo cp /home/opc/.ssh/authorized_keys.bak /home/opc/.ssh/authorized_keys",
#      "rm -f /home/opc/.ssh/authorized_keys.bak",
#      "chown -R opc /home/opc/.ssh/authorized_keys"
#    ]
#  }
#}
