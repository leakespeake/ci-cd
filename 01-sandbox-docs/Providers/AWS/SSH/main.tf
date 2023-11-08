# DEPLOY SINGLE UBUNTU SERVER TO TEST SSH ACCESS AND USE OF OUR NEWLY REGISTERED KEY PAIRS

# Allow any Terraform 12.x version - show via; terraform version

terraform {
  required_version = ">= 0.12, < 0.13"
}

# Set the provider as AWS and allow any 2.x version - show via; terraform version
provider "aws" {
    region = "us-east-2"
    version = "~> 2.0"
}

# Create a t2.micro spec EC2 instance using the Ubuntu 18 ami
# Pass it the ID of the security group resource below using a RESOURCE ATTRIBUTE REFERENCE - <PROVIDER=aws>_<TYPE=security_group>_.<NAME=ssh-instance>.<ATTRIBUTE=id>
resource "aws_instance" "ssh-example" {
    ami                     = "ami-0c55b159cbfafe1f0"
    instance_type           = "t2.micro"
    vpc_security_group_ids  = [aws_security_group.ssh-instance.id]
    key_name                = "dem-keys-2020"

# Pass a shell script to User Data to write Hello World into index.html then use busybox to launch a webserver on 8080 to serve it
# Uses Terraforms HEREDOC SYNTAX of <<-EOF and EOF to create multi line strings without inserting newline characters
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello World" > index.html
                nohup busybox httpd -f -p ${var.ingress_port1} &
                EOF

# Name the EC2 instance using a tag
    tags = {
        Name = "SSH Example"
    }
}

# Provides an EC2 key pair resource. Either use this code - OR - upload the key pair's public key to AWS > EC2 > Key Pairs (matching the 'key_name' value in the EC2 resource)
resource "aws_key_pair" "dem-keys-2020" {
  key_name   = "dem-keys-2020"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDPcIV7FhsEq04o9+Og2QbpRmRoX+b+CSoHiXGSEm+8psvubqMz59rVwVtHF/oD257a56KUD6S3E0xrjq+H/haYbPke4r7g/EkkVN8XFLV6E1sNZfzIpwPSsn+PVlHGtsQMwGeVoy/zq8P48BGKMyaUAylwuvX4kuZSkEpwn8ogiSJ64fR2ggyPVs4riKmIA5SFfaNY3CqnyIyRCqVSED8drDk0EyOK+04iFdZX0etpkZKHfPi79RZ6IhPdorR0vql1FLbA4at5IaOHfwUXDJK/he5zAtd3HFjNL6PSpjkO5WeQeVSSbrKNciCthYm2Fqzo9AMGEaCKlBn+cSjXCY9D barry@LAPTOP-FSQR2GTV"
}

# Create a security group resource named 'ssh-instance' to allow inbound traffic on tcp/8080 from anyone (0.0.0.0/0) and SSH requests from me only!
resource "aws_security_group" "ssh-instance" {
    name = var.security_group_name
    
    ingress {
        from_port   = var.ingress_port1
        to_port     = var.ingress_port1
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }

    ingress {
        from_port   = var.ingress_port2
        to_port     = var.ingress_port2
        protocol    = "tcp"
        cidr_blocks = ["92.238.177.185/32"]
        }

# By default, AWS creates an ALLOW ALL egress rule when creating a new Security Group inside of a VPC - Terraform removes it so you need to specifiy it in the code.
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
 }
}