# CREATE A MYSQL DATABASE INSTANCE USING AWS RELATIONAL DATABASE SERVICE (RDS) 
# PASS THE DATABASE PASSWORD TO TERRAFORM VIA AN ENVIRONMENT VARIABLE - export TF_VAR_db_password="<database password>" - see variables.tf

# Allow any Terraform 12.x version - show via; terraform version

terraform {
    required_version = ">= 0.12, < 0.13"
}

# Set the provider as AWS and allow any 2.x version - show via; terraform version
provider "aws" {
  region = "us-east-2"
  version = "~> 2.0"
}

# Create the MySQL database instance in RDS
resource "aws_db_instance" "example" {
    identifier_prefix   = "terraform-up-and-running"
    engine              = "mysql"
    allocated_storage   = 10
    instance_class      = "db.t2.micro"
    skip_final_snapshot = true
    name                = "example_database"
    username            = "admin"
    password            = var.db_password
}

