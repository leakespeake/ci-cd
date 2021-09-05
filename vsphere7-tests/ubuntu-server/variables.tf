# VSPHERE AUTHENTICATION

variable vcenter_server {
  type = string
  description = "The vCenter server hostname, IP, or FQDN"
  default = "vcsa.int.leakespeake.com"
}

variable vcenter_username {
  type = string
  description = "The username for authenticating to vCenter"
  default = "administrator@vsphere.local"
}

variable vcenter_password {
  type = string
  description = "The password for authenticating to vCenter - no default set to allow for run time prompt"
}

# VSPHERE VARIABLES

variable "datacenter" {
  description = "The datacenter to deploy the VM"
  default     = "home-dc-01"
}

variable "datastore" {
  description = "The datastore to deploy the VM - check free space first!"
  default     = "NAS-datastore-01"
}

variable "cluster" {
  description = "The cluster to deploy the VM"
  default     = "home-cluster-01"
}

variable "network" {
  description = "The network to deploy the VM"
  default     = "VM Network"
}

variable "template" {
  description = "The name of the template available on the selected vCenter server"
  default     = "ubuntu-server-20-04-2-20210905T095306Z"
}

variable "folder" {
  description = "The path to the folder to put the VM in, relative to the datacenter that the resource pool is in"
  default     = "Testing"
}

# RESOURCE VARIABLES

variable "node_count" {
  description = "The number of instances you want deploy from the template"
  default     = 2
}

variable "vmname" {
  description = "The base name of the resulting VM(s)"
  default     = "my-testvm"
}

variable "vmnamesuffix" {
  description = "The DNS domain suffix - to be appended to var.vmname - match to the Linux customization option 'domain'"
  default     = "int.leakespeake.com"
}

variable "cpus" {
  description = "The number of CPU (cores per CPU) for the VM"
  default     = 1
}

variable "memory" {
  description = "The RAM size in megabytes"
  default     = 2048
}

variable "nested_hv" {
  type = bool  
  description = "Enable or disable nested virtualization in the guest"
  default     = true
}

# RESOURCE CUSTOMIZATION VARIABLES

variable "domain" {
  description = "The domain name for this VM. This, along with host_name, make up the FQDN of this VM - match to the resource variable 'vmnamesuffix'"
  default     = "int.leakespeake.com"
}

variable "ipv4" {
  description = "The IP's to set for each VM - must exist within the var.network range - used with the count argument to calculate VM numbers"
  type = list(string)
  default = ["192.168.0.160"]
}

variable "ipv4_mask" {
  description = "The subnet mask of the ipv4 network"
  default = "24"
}

variable "ipv4_gateway" {
  description = "The default gateway of the ipv4 network"
  default = "192.168.0.250"
}

variable "dns_servers" {
  description = "Set DNS configuration"
  type = list(string)
  default = ["192.168.0.113", "194.168.4.100", "194.168.8.100"]
}

