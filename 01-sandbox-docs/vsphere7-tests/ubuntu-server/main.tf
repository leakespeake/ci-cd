resource "vsphere_virtual_machine" "vm" {
  # use the length function to return the number of items in the 'ipv4' array - see variables.tf - or simply use var.node_count
  count = length(var.ipv4)
  # utlize {count.index + 1} to start the sequential numbering from '01' in the array index (not '00')
  name = "${var.vmname}-0${count.index + 1}.${var.vmnamesuffix}"

  folder   = var.folder
  num_cpus = var.cpus
  memory   = var.memory

  # If deploying a VM within a nested vSphere environment, you must enable the nested_hv_enabled argument to facilitate nested virtualization in the guest
  nested_hv_enabled = var.nested_hv

  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  guest_id         = data.vsphere_virtual_machine.template.guest_id
  scsi_type        = data.vsphere_virtual_machine.template.scsi_type

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = data.vsphere_virtual_machine.template.network_interface_types[0]
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template.disks.0.thin_provisioned
  }

  # Changing any option in 'clone' after creation forces a new resource
  clone {
    template_uuid = data.vsphere_virtual_machine.template.id

    # Linux options in full: host_name, domain, hw_clock_utc, time_zone (last 2 are optional)
    customize {
      linux_options {
        host_name = "${var.vmname}-0${count.index + 1}"
        domain    = var.domain
      }

      # utlize [count.index] for 'ipv4_address' to iterate through the items in the 'ipv4' array - see variables.tf
      network_interface {
        ipv4_address = var.ipv4[count.index]
        ipv4_netmask = var.ipv4_mask
      }

      ipv4_gateway    = var.ipv4_gateway
      dns_server_list = var.dns_servers
    }
  }
}

resource "dns_a_record_set" "my-test-vms" {
  count     = length(var.ipv4)
  zone      = "int.leakespeake.com."
  name      = "${var.vmname}-0${count.index + 1}"
  addresses = "${var.ipv4}"
  ttl       = 300
}