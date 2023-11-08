# No 'default' parameter set for "db_password" variable - i.e. don't store password in plain text
# Terraform looks for environment variables of the name; TF_VAR_<variable name> so we can set the following in Git Bash;
# $  export TF_VAR_db_password="<database password>" [The space before 'export' prevents the secret being stored in Bash history]
# $ terraform apply
# env | grep TF_

variable "db_password" {
    description = "The database password"
    type        = string
}
