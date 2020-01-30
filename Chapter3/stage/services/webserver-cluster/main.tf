# DEPLOY A UBUNTU WEB SERVER CLUSTER USING AN AWS ASG (AUTO SCALING GROUP) AND ALB (APPLICATION LOAD BALANCER) FRONT END

# Allow any Terraform 12.x version - show via; terraform version

terraform {
    required_version = ">= 0.12, < 0.13"
}

# Set the provider as AWS and allow any 2.x version - show via; terraform version
provider "aws" {
    region = "us-east-2"
    version = "~> 2.0"
}

# Create a LAUNCH CONFIGURATION (how to configure each EC2 instance in the ASG) - replaces the aws_instance resource used prior
# Create t2.micro spec EC2 instances using the Ubuntu 18 ami
# Pass it the ID of the security group resource below using a RESOURCE ATTRIBUTE REFERENCE - <PROVIDER=aws>_<TYPE=security_group>_.<NAME=instance>.<ATTRIBUTE=id>
resource "aws_launch_configuration" "example-config" {
    image_id        = "ami-0c55b159cbfafe1f0"
    instance_type   = "t2.micro"
    security_groups = [aws_security_group.instance.id]

    user_data = <<EOF
                #!/bin/bash
                echo "hello there, fancy a burger?" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF

# Required when using a launch configuration with an asg - i.e. create replacement resource first, prior to deleting the old one
    lifecycle {
        create_before_destroy = true
    }
}

# Create the ASG (AUTO SCALING GROUP)
# Link it to the LAUNCH CONFIGURATION using a RESOURCE ATTRIBUTE REFERENCE - <PROVIDER=aws>_<TYPE=launch_configuration>_.<NAME=example-config>.<ATTRIBUTE=name>
# Pull the subnet ids from the aws_subnet_ids DATA SOURCE - tell the ASG to use them via the vpc_zone_identifier ARGUMENT
# Point the ASG to the load balancer TARGET GROUP 
# Set minumum and maximum EC2 node size of the group
resource "aws_autoscaling_group" "example-asg" {
    launch_configuration    = aws_launch_configuration.example-config.name
    vpc_zone_identifier     = data.aws_subnet_ids.default.ids

    target_group_arns       = [aws_lb_target_group.asg.arn]
    health_check_type       = "ELB"     # ELB will automatically replace instances if the TARGET GROUP reports them as unhealthy
    
    min_size                = 2
    max_size                = 4

    tag {
        key                 = "Name"
        value               = "terraform-asg-example"
        propagate_at_launch = true
    }
}

# Create a SECURITY GROUP resource named 'instance' to allow inbound traffic on tcp/8080 from anyone (0.0.0.0/0)  
resource "aws_security_group" "instance" {
    name            = var.asg_security_group_name
    
    ingress {
        from_port   = var.server_port
        to_port     = var.server_port
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        }
}

# Use the aws_vpc DATA SOURCE to pull read-only data from the default vpc;
# data "<PROVIDER=aws>_<TYPE=vpc>" "<NAME=default>" {
#    [SEARCH FILTER=default = true]
#}
data "aws_vpc" "default" {
    default = true
} 

# Use the aws_subnet_ids DATA SOURCE to look up the subnets from the default vpc (aws_vpc DATA SOURCE above);
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Create the ALB (APPLICATION LOAD BALANCER), use the subnets in the default vpc and reference its SECURITY GROUP
resource "aws_lb" "example" {
    name                = var.alb_name
    load_balancer_type  = "application"
    subnets             = data.aws_subnet_ids.default.ids
    security_groups     = [aws_security_group.alb.id]
}

# Create a LISTENER for the ALB and reference the ALB using the load_balancer_arn ARGUMENT
resource "aws_lb_listener" "http" {
    load_balancer_arn   = aws_lb.example.arn
    port                = 80
    protocol            = "HTTP"

      # By default, return a simple 404 page
    default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found"
      status_code  = 404
    }
  }
}

# Create a new SECURITY GROUP for the ALB
resource "aws_security_group" "alb" {
    name                = var.alb_security_group_name

    # Allow inbound HTTP requests on port 80 for the LISTENER
    ingress {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    # Allow all outbound requests so the ALB can perform health checks
    egress {
        from_port       = 0
        to_port         = 0
        protocol        = "-1"
        cidr_blocks     = ["0.0.0.0/0"]
    }
}

# Create a TARGET GROUP for the ASG, performing health checks to only send requests to healthy nodes
resource "aws_lb_target_group" "asg" {
      name      = var.alb_name
      port      = var.server_port
      protocol  = "HTTP"
      vpc_id    = data.aws_vpc.default.id
      
      health_check {
          path                = "/"
          protocol            = "HTTP"
          matcher             = "200"
          interval            = 15
          timeout             = 3
          healthy_threshold   = 2
          unhealthy_threshold = 2
          }       
}

# Create a LISTENER RULE to send requests that match any path to the TARGET GROUP that contains the ASG
resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority     = 100

    condition {
        path_pattern {
            values = ["*"]
        }
    }

    action {
        type                = "forward"
        target_group_arn    = aws_lb_target_group.asg.arn
    }
}
