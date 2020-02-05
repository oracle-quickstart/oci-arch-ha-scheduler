# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

output "subnets" {
  description = "The Subnet(s) that have been created as a part of this module."
  value       = module.oci_subnets.subnets
}

output "dhcp_options" {
  value = module.oci_network.dhcp_options
}

output "route_tables" {
  value = module.oci_network.route_tables
}

output "oci_ha_scheduler_nsg_rules" {
  description = "The HA Scheduler NSGs."
  value       = module.oci_ha_scheduler_security_policies.nsg_rules
}

output "oci_ha_scheduler_util_nsg_rules" {
  description = "The HS Scheduler util NSGs."
  value       = module.oci_ha_scheduler_util_security_policies.nsg_rules
}

output "oci_ha_scheduler_fss_sec_list" {
  description = "The FSS Security List."
  value       = module.oci_ha_scheduler_fss_sec_list.security_lists
}


