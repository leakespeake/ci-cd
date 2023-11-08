variable "ingress_port1" {
  description = "The port the server will use for HTTP requests"
  type        = number
  default     = 8080
}

variable "ingress_port2" {
  description = "The port the server will use for SSH requests"
  type        = number
  default     = 22
}

variable "security_group_name" {
  description = "The name of the security group"
  type        = string
  default     = "ssh-example-instance"
}