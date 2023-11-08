# DEPLOY SINGLE UBUNTU SERVER

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
# Pass it the ID of the security group resource below using a RESOURCE ATTRIBUTE REFERENCE - <PROVIDER=aws>_<TYPE=security_group>_.<NAME=instance>.<ATTRIBUTE=id>
resource "aws_instance" "example" {
    ami                     = "ami-0c55b159cbfafe1f0"
    instance_type           = "t2.micro"
    vpc_security_group_ids  = [aws_security_group.instance.id]

# Pass a shell script to User Data to write Hello World into index.html then use busybox to launch a webserver on 8080 to serve it
# Uses Terraforms HEREDOC SYNTAX of <<-EOF and EOF to create multi line strings without inserting newline characters
    user_data = <<-EOF
                #!/bin/bash
                echo "Hello World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

# Name the EC2 instance using a tag
    tags = {
        Name = "Barrys Example"
    }
}

# Create a security group resource named 'instance' to allow inbound traffic on tcp/8080 from anyone (0.0.0.0/0)  
resource "aws_security_group" "instance" {
    name = var.security_group_name
    
    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }
}
