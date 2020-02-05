# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

resource "null_resource" "install_oci_cli" {
  count = var.cluster_size

  provisioner "remote-exec" {
    connection {
      user        = "opc"
      agent       = false
      private_key = "${chomp(file(var.ssh_private_key_path))}"
      timeout     = "10m"
      host        = module.oci_instances.instance["${var.names_prefix}-inst-${count.index + 1}"].public_ip
    }

    inline = [
      "sudo -s bash -c 'yum -y install yum-utils'",
      "sudo -s bash -c 'yum-config-manager --enable ol7_developer ol7_developer_epel'",
      "sudo -s bash -c 'yum -y install python-oci-sdk python-oci-cli'"
    ]
  }

  depends_on = []
}
