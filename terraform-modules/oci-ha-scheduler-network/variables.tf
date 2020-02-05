# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

#compartment
variable "default_compartment_id" {}


# naming convension
variable "names_prefix" {}
variable "defined_tags" {}
variable "freeform_tags" {}

# networking details
variable "vcn_id" {}
variable "vcn_cidr" {}
variable "oci_ha_scheduler_subnet_cidr" {}
variable "oci_ha_scheduler_route_table" {}
variable "dhcp_options" {}
variable "assign_public_ip" {
  type = bool
}

#OCI HA Scheduler Util Nodes

variable "provision_util_node" {
  type = bool
}

# OCI HA Scheduler FSS
variable "file_system" {}


