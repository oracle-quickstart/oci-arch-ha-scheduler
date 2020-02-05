# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

locals {
  instances_default_vnics = {
    for i in range(var.cluster_size) : "${var.names_prefix}-inst-${i + 1}" => {
      instance_id = module.oci_instances.instance["${var.names_prefix}-inst-${i + 1}"].id,
      "vnic_0_id" = {
      for v in data.oci_core_vnic_attachments.node_ens3_vnic_attachments : "vnic_0_id" => v.vnic_attachments[0].vnic_id if v.instance_id == module.oci_instances.instance["${var.names_prefix}-inst-${i + 1}"].id }["vnic_0_id"],
      "vnic_attachment_id" = {
      for v in data.oci_core_vnic_attachments.node_ens3_vnic_attachments : "vnic_attachment_id" => v.vnic_attachments[0].id if v.instance_id == module.oci_instances.instance["${var.names_prefix}-inst-${i + 1}"].id }["vnic_attachment_id"]
    }
  }
  oci_ha_scheduler_instances_private_ips = [for i in range(var.cluster_size) : module.oci_instances.instance["${var.names_prefix}-inst-${i + 1}"].private_ip]
}

resource "null_resource" "upload_crond_config" {
  count = var.cluster_size

  provisioner "file" {
    connection {
      user        = "opc"
      agent       = false
      private_key = "${chomp(file(var.ssh_private_key_path))}"
      timeout     = "10m"
      host        = module.oci_instances.instance["${var.names_prefix}-inst-${count.index + 1}"].public_ip
    }

    source      = "./scripts/ntp_install_configure.sh"
    destination = "/tmp/ntp_install_configure.sh"
  }

  provisioner "file" {
    connection {
      user        = "opc"
      agent       = false
      private_key = "${chomp(file(var.ssh_private_key_path))}"
      timeout     = "10m"
      host        = module.oci_instances.instance["${var.names_prefix}-inst-${count.index + 1}"].public_ip
    }

    source      = "./scripts/keepalived_install.sh"
    destination = "/tmp/keepalived_install.sh"
  }

  provisioner "file" {
    connection {
      user        = "opc"
      agent       = false
      private_key = "${chomp(file(var.ssh_private_key_path))}"
      timeout     = "10m"
      host        = module.oci_instances.instance["${var.names_prefix}-inst-${count.index + 1}"].public_ip
    }

    source      = "./scripts/configure-crond.sh"
    destination = "/tmp/configure-crond.sh"
  }

  provisioner "remote-exec" {
    connection {
      user        = "opc"
      agent       = false
      private_key = "${chomp(file(var.ssh_private_key_path))}"
      timeout     = "10m"
      host        = module.oci_instances.instance["${var.names_prefix}-inst-${count.index + 1}"].public_ip
    }

    inline = [
      "chmod uga+x /tmp/ntp_install_configure.sh",
      "sudo su - root -c \"/tmp/ntp_install_configure.sh\"",
      "chmod uga+x /tmp/keepalived_install.sh",
      "sudo su - root -c \"/tmp/keepalived_install.sh ${module.oci_instances.instance["${var.names_prefix}-inst-${count.index + 1}"].private_ip} \"${join(",", local.oci_ha_scheduler_instances_private_ips)}\" ${count.index + 1} ${count.index > 0 ? "100" : "200"} ${count.index > 0 ? "BACKUP" : "MASTER"} ${"${var.names_prefix}-inst-${count.index + 1}"} ${local.instances_default_vnics["${var.names_prefix}-inst-${count.index + 1}"].vnic_0_id} \"",
      "chmod uga+x /tmp/configure-crond.sh",
      "sudo su - root -c \"/tmp/configure-crond.sh '${var.scheduler_frequency}' ${count.index} '${var.custom_command}'\"",


    ]
  }
  depends_on = ["null_resource.mount_shared_storage"]
}

data "oci_core_vnic_attachments" "node_ens3_vnic_attachments" {
  #Required
  count          = var.cluster_size
  compartment_id = var.default_compartment_id

  #Optional
  instance_id = module.oci_instances.instance["${var.names_prefix}-inst-${count.index + 1}"].id
}
