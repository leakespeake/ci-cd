variable "server_port" {
    description = "The port used for http requests"
    type        = number
    default     = 8080
}

variable "alb_name" {
  description = "The name of the ALB"
  type        = string
  default     = "terraform-asg-example"
}

variable "asg_security_group_name" {
    description = "The name of the ASG security group"
    type        = string
    default     = "terraform-example-asg"
}

variable "alb_security_group_name" {
    description = "The name of the ALB security group"
    type        = string
    default     = "terraform-example-alb"
}