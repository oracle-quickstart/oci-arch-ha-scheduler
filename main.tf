# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

module "oci-ha-scheduler-network" {
  source = "./terraform-modules/oci-ha-scheduler-network"

  # compartment
  default_compartment_id = var.network_compartment_id != null ? var.network_compartment_id : var.default_compartment_id

  # naming convensions
  names_prefix  = var.names_prefix
  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags

  # networking details
  vcn_id              = var.vcn_id
  vcn_cidr            = data.oci_core_vcn.vcn.cidr_block
  oci_ha_scheduler_subnet_cidr = var.oci_ha_scheduler_subnet_cidr
  oci_ha_scheduler_route_table = var.oci_ha_scheduler_route_table
  dhcp_options        = var.dhcp_options
  assign_public_ip    = var.assign_public_ip

  # OCI HA Scheduler Util Nodes
  provision_util_node = var.provision_util_node

  # OCI HA Scheduler FSS
  file_system = var.file_system

}

module "oci-ha-scheduler-shared-storage" {

  source = "./terraform-modules/oci-ha-scheduler-shared-storage"

  providers = {
    oci.custom_provider = "oci"
  }

  #compartment
  default_compartment_id = var.fss_compartment_id != null ? var.fss_compartment_id : var.default_compartment_id

  #naming convensions
  names_prefix  = var.names_prefix
  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags


  #networking
  oci_ha_scheduler_subnet = module.oci-ha-scheduler-network.subnets["${var.names_prefix}-subnet"].id

  file_system = var.file_system
}

# create the aditional VMs block volumes

module "oci-ha-scheduler-volumes" {

  source = "./terraform-modules/oci-ha-scheduler-volumes"

  cluster_size                = var.cluster_size
  default_compartment_id      = var.block_storage_compartment_id != null ? var.block_storage_compartment_id : var.default_compartment_id
  names_prefix                = var.names_prefix
  volumes_backup_policy       = var.volumes_backup_policy
  aditional_block_volume_size = var.aditional_block_volume_size
  tenancy_compartment_id      = var.tenancy_id
  defined_tags                = var.defined_tags
  freeform_tags               = var.freeform_tags

}

module "oci-ha-scheduler-compute" {
  source = "./terraform-modules/oci-ha-scheduler-compute"

  default_compartment_id = var.compute_compartment_id != null ? var.compute_compartment_id : var.default_compartment_id
  tenancy_compartment_id = var.tenancy_id

  cluster_size          = var.cluster_size
  names_prefix          = var.names_prefix
  ssh_private_key_path  = var.ssh_private_key_path
  ssh_public_key_path   = var.ssh_public_key_path
  shape                 = var.shape
  image_name            = var.image_name
  volumes_backup_policy = var.volumes_backup_policy
  oci_ha_scheduler_subnet        = module.oci-ha-scheduler-network.subnets["${var.names_prefix}-subnet"].id
  oci_ha_scheduler_subnet_cidr   = module.oci-ha-scheduler-network.subnets["${var.names_prefix}-subnet"].cidr_block
  assign_public_ip      = var.assign_public_ip
  nsg_ids               = [module.oci-ha-scheduler-network.oci_ha_scheduler_nsg_rules[0].network_security_group_id]
  block_volumes = [for s in {
    for i in range(var.cluster_size) : "${var.names_prefix}-${i + 1}-volume01" => {
      volume = "${var.names_prefix}-${i + 1}-volume01",
      details = {
        volume_id        = contains(keys(module.oci-ha-scheduler-volumes.block_volumes), "${var.names_prefix}-${i + 1}-volume01") ? module.oci-ha-scheduler-volumes.block_volumes["${var.names_prefix}-${i + 1}-volume01"].id : ""
        attachment_type  = "iscsi",
        volume_mount_dir = var.aditional_block_volume_mount_point
      }
    }
  } : list(s)]
  scheduler_frequency = var.scheduler_frequency
  custom_command = var.custom_command
  defined_tags     = var.defined_tags
  freeform_tags    = var.freeform_tags

  # OCI ha-scheduler Shared Storage
  nfs_mount          = var.file_system != null ? "${module.oci-ha-scheduler-shared-storage.file_system.mount_targets.fs1_mt1.hostname_label}.${data.oci_core_subnet.ha_scheduler_subnet[0].subnet_domain_name}:${module.oci-ha-scheduler-shared-storage.file_system.mount_targets.fs1_mt1.export_sets.fs1_mt1-export-set.exports[0].path}" : null
  nfs_mount_point    = var.fss_mount_point
  file_system_config = var.file_system
}

module "oci-ha-scheduler-util-compute" {
  source = "./terraform-modules/oci-ha-scheduler-util-compute"

  default_compartment_id = var.compute_compartment_id != null ? var.compute_compartment_id : var.default_compartment_id
  provision_util_node    = var.provision_util_node
  names_prefix           = var.names_prefix
  ssh_private_key_path   = var.ssh_private_key_path
  ssh_public_key_path    = var.ssh_public_key_path
  image_name             = var.image_name
  oci_ha_scheduler_subnet         = module.oci-ha-scheduler-network.subnets["${var.names_prefix}-subnet"].id
  assign_public_ip       = var.assign_public_ip
  nsg_ids                = var.provision_util_node == false ? [] : [module.oci-ha-scheduler-network.oci_ha_scheduler_util_nsg_rules[0].network_security_group_id]
  defined_tags           = var.defined_tags
  freeform_tags          = var.freeform_tags
}

# create one volume group per region AD and add to it the ha-scheduler instances block and boot volumes  

module "oci-ha-scheduler-vol-groups" {

  source = "./terraform-modules/oci-ha-scheduler-vol-groups"

  default_compartment_id = var.compute_compartment_id != null ? var.compute_compartment_id : var.default_compartment_id
  tenancy_compartment_id = var.tenancy_id
  names_prefix           = var.names_prefix
  block_volumes          = module.oci-ha-scheduler-volumes.block_volumes
  instances              = module.oci-ha-scheduler-compute.ha_scheduler_instances.instance
  defined_tags           = var.defined_tags
  freeform_tags          = var.freeform_tags
  cluster_size           = var.cluster_size
}

module "oci-ha-scheduler-iam" {
  source = "./terraform-modules/oci-ha-scheduler-iam"

  // IAM Details

  providers = {
    oci.oci_home = "oci.oci_home"
  }

  default_compartment_id = var.iam_compartment_id != null ? var.iam_compartment_id : var.default_compartment_id
  tenancy_compartment_id = var.tenancy_id

  // naming convension
  names_prefix  = "${var.names_prefix}"
  defined_tags  = var.defined_tags
  freeform_tags = var.freeform_tags

  // instances
  instances_ids = [for instance in module.oci-ha-scheduler-compute.ha_scheduler_instances.instance : instance.id]
}


