module "the-parent-trap" {
  source = "git@github.com:leakespeake/terraform-reusable-modules.git//vsphere/template-cloning/linux/ubuntu-server-20-04?ref=26decc2"

  vcenter_password  = var.vcenter_password
  
  vmname            = "parent-vm-stg"

  network           = "10.2.2.0/24_stg"
  
  ipv4              = ["10.2.2.80", "10.2.2.81"]
  
  ipv4_gateway      = "10.2.2.1"
}