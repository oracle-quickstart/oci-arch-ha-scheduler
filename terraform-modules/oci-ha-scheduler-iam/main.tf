# Copyright (c) 2020 Oracle and/or its affiliates.
# Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

module "oci_iam_dynamic_groups" {

  source = "github.com/oracle-terraform-modules/terraform-oci-tdf-iam.git?ref=v0.1.8"

  providers = {
    oci.oci_home = "oci.oci_home"
  }
  iam_config = {
    default_compartment_id = var.tenancy_compartment_id
    default_defined_tags   = var.defined_tags
    default_freeform_tags  = var.freeform_tags
    compartments           = null
    groups                 = null
    users                  = null
    dynamic_groups = {
      "${lower(format("%.30s", format("%s%s", var.names_prefix, "-dynamic-group")))}" = {
        compartment_id = null
        description    = "OCI-HA-Scheduler Dynamic Group needed by the OCI-HA-Scheduler Cluster VMs to be able to call the crond custom script."
        instance_ids   = var.instances_ids
        defined_tags   = null
        freeform_tags  = null
      }
    }
    policies = null
  }
}

module "oci_iam_policies" {

  source = "github.com/oracle-terraform-modules/terraform-oci-tdf-iam.git?ref=v0.1.8"

  providers = {
    oci.oci_home = "oci.oci_home"
  }

  # Policies

  iam_config = {
    default_compartment_id = var.tenancy_compartment_id
    default_defined_tags   = var.defined_tags
    default_freeform_tags  = var.freeform_tags
    compartments           = null
    groups                 = null
    users                  = null
    dynamic_groups         = null
    policies = {
      "${lower(format("%.30s", format("%s%s", var.names_prefix, "-policy")))}" = {
        compartment_id = null
        description    = "Policy to enable the Dynamic Group containing the OCI-HA-Scheduler cluster nodes to make rest api calls."
        statements     = ["Allow dynamic-group ${module.oci_iam_dynamic_groups.iam_config.dynamic_groups["${lower(format("%.30s", format("%s%s", var.names_prefix, "-dynamic-group")))}"].name} to manage all-resources in compartment ${data.oci_identity_compartment.oci_ha_scheduler_compartment.name}", "Allow dynamic-group ${module.oci_iam_dynamic_groups.iam_config.dynamic_groups["${lower(format("%.30s", format("%s%s", var.names_prefix, "-dynamic-group")))}"].name} to manage all-resources in compartment ${data.oci_identity_compartment.oci_ha_scheduler_compartment.name}"]
        defined_tags   = null
        freeform_tags  = null
        version_date   = null
      }
    }
  }
}

data "oci_identity_compartment" "oci_ha_scheduler_compartment" {
  #Required
  id = "${var.default_compartment_id}"
}
