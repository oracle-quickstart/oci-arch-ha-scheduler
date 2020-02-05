# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.


variable "default_compartment_id" {}

variable "tenancy_compartment_id" {}

variable "cluster_size" {}

# naming convension
variable "names_prefix" {}
variable "defined_tags" {}
variable "freeform_tags" {}

# OCI HA Scheduler Instances

variable "ssh_private_key_path" {}
variable "ssh_public_key_path" {}
variable "shape" {}
variable "image_name" {}
variable "nsg_ids" {
  type = list
}

variable "block_volumes" {
  type = list
}
variable "volumes_backup_policy" {}

# OCI HA Scheduler Shared Storage

variable "nfs_mount" {}
variable "nfs_mount_point" {}
variable "file_system_config" {}

# HA Scheduler instances configuration

# Scheduler Configuration
variable "scheduler_frequency" {}
# Custom command to be run be the crond
variable "custom_command" {
  type        = string
  default     = "/usr/bin/oci --auth=instance_principal compute image list --compartment-id ocid1.compartment.oc1..aaaaaaaacnmuyhg2mpb3z6v6egermq47nai3jk5qaoieg3ztinqhamalealq"
  description = "Custom command to be run be the crond"
}

#neworking
variable "oci_ha_scheduler_subnet" {}
variable "oci_ha_scheduler_subnet_cidr" {}
variable "assign_public_ip" {}







