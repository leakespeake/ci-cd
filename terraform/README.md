# JENKINS INTEGRATION WITH TERRAFORM
NOTE: These steps are intended to be setup later via **Jenkins Configuration as Code** using the dedicated Configuration as Code plugin, to allow all Jenkins configuration to be orchestrated via a `.yaml` file.

---

## Terraform Plugin
First logon to Jenkins and install the plugin for Terraform via *Manage Jenkins > Manage Plugins > Available* and search Terraform. 

Post install you'll see the `Terraform installations` section within *Manage Jenkins > Tools... Terraform installations* - make sure the latest binary is installed.

That's all we'll need to run Terraform commands on Jenkins.

## Jenkins Pipeline
Simply setup a new pipeline as per;

- Definition: Pipeline script from SCM
- SCM: Git
- Repository URL: https://github.com/leakespeake/terraform-projects.git
- Credentials: None (public repo)
- Script Path: Jenkinsfile

The Jenkinsfile script should include a `step` to reference both the ID of the Vault Secret Text Credential (`vcenter_password`) and the Terraform variable (TF_VAR_) that will be used to load the secret value - in this example `TF_VAR_vcenter_password`;
```
    stages{   
      stage('Vsphere Echo Test') {
        steps {
            // load our Vault sourced secret value directly into the TF_VAR_ Terraform environment variable
            withCredentials([vaultString(credentialsId: 'vcenter_password', variable: 'TF_VAR_vcenter_password')]) {
                sh "echo 'Here you can use the environment variable TF_VAR_vcenter_password'"
            }
          }
        }  
```
Terraform searches the environment of its own process for environment variables named **TF_VAR_** followed by the name of a declared variable. This is useful when running Terraform in automation. Obviously there are many other ways Terraform can handle variables - see https://developer.hashicorp.com/terraform/language/values/variables - but our use case here is automation.

After the pipeline run you will see that the secret value has been masked in the builds Console Output.

### Build Triggers
No automatic build triggers are required in this homelab scenario. However, the `Jenkinsfile` that Jenkins will checkout (in the root of this repository) is set to;

- use the **environment** directive to allow setting the directory path to the .tf files we want to run - simply change the **DIR_PATH** and **VM_NAME** values - these are then called via the **env** object throughout the pipeline stages - once we commit this change to the repo, we can run our Jenkins pipeline to checkout the updated file and create our resources on vCenter Server

- use the **parameters** directive to allow us to control (via the **params** object) whether Jenkins will skip the approval stage (to auto-approve the`tfplan`) - OR - whether to invoke the `terraform destroy` stages to remove our resources from vCenter

## TF Switch
TBC