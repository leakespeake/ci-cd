terraform {
    backend "s3" {
        bucket      = "leakespeake-terraform-state-files"
        key         = "global/s3/Chapter3/stage/services/webserver-cluster-01/terraform.tfstate"
        region      = "us-east-2"

        dynamodb_table  = "leakespeake-terraform-state-lock"
        encrypt         = true
    }
}