# JENKINS INTEGRATION WITH VAULT
NOTE: These steps are intended to be setup later via **Jenkins Configuration as Code** using the dedicated Configuration as Code plugin, to allow all Jenkins configuration to be orchestrated via a `.yaml` file.

---

Jenkins has the concept of a "Credential store" but it is static in nature; the secrets are stored in the underlying filesystem hashed. It requires an admin to load them manually and is a single attack vector for potentially compromising credentials. 

By using Vault instead, credentials are dynamic in nature, short lived, and can be revoked easily. Access is programmatical, so reduces the difference between the way credentials are consumed in different environments. Policy is handled centrally there too, to carefully control what paths & secrets Jenkins can access.

## VAULT
First logon to Vault with our LDAP account;
```
vault login --method=ldap user=$USER
```

### Enable AppRole
The best authentication method for Jenkins will be **AppRole** as it allows machines or apps to authenticate with Vault-defined roles. This auth method is oriented to automated workflows (machines and services), and not intended for human operators.

Enable the approle authentication method;
```
vault auth enable approle
```
*Success! Enabled approle auth method at: approle/* 

### Create a Vault Role
We then need to create a `role` for the Jenkins AppRole authentication method to associate with a Vault policy (created below);
```
vault write auth/approle/role/jenkins-role token_num_uses=0 secret_id_num_uses=0 policies="jenkins"
vault read auth/approle/role/jenkins-role
```

### Role ID and Secret ID
Now we have our role created, to login successfully we need the **role ID** and **secret ID** - output these via;
```
vault read auth/approle/role/jenkins-role/role-id
vault write -f auth/approle/role/jenkins-role/secret-id
```
So at this point we've enabled AppRole authentication, created its corresponding role, and now need to create the Vault policy we specified in the role creation - i.e. `policies="jenkins"`

### Create a Vault Policy
First, create a policy file - in this case `jenkins_policy.hcl` that defines what can and cannot be done within the specified Vault paths;

```
path "kv1/*"
{
  capabilities = ["read", "list"]
}

path "kv2/*"
{
  capabilities = ["read", "list"]
}
```
Then write the policy to the remote Vault instance - based off the rule definitions in the .hcl file;
```
vault policy write jenkins jenkins_policy.hcl
```
*Success! Uploaded policy: jenkins*

Lastly, ensure we have a test secret in Vault that we can use to test Jenkins with in the setup below;
```
vault kv get kv1/test
vault kv get kv2/test2
```
These tests both `Version 1` and `Version 2` Key/Values.

---

## JENKINS
Logon to Jenkins!

### Install the Vault Plugin and configure it
Install the 'Hashicorp Vault' plugin via *Manage Jenkins > Plugins > Available Plugins*... then restart Jenkins.

Official guide here https://plugins.jenkins.io/hashicorp-vault-plugin/

This plugin allows authenticating against Vault using the `AppRole` authentication backend and adds a build wrapper to set environment variables from a Vault secret. Secrets are masked in the build log so you can't accidentally print them. It also has the ability to inject Vault credentials into a build pipeline (or freestyle job) for fine-grained Vault interactions.

Plugin configuration is done via the Vault parameters, now available in *Manage Jenkins > System... Vault Plugin* - configured here as;

- Vault URL: https://vault-prd-01.int.leakespeake.com:8200
- Vault Credential: select `Add` then;

### Create a Vault App Role Credential
We need to create a `Vault Credential` which will be used by the Vault plugin on Jenkins to consume credentials from Vault during a pipeline run. The credential type you provide determines what authentication backend will be used for Jenkins to successfully gain a Vault token. We are using the `AppRole` authentication backend, so will create a `Vault App Role Credential` as per;

- Domain: Global credentials (unrestricted)
- **Kind: Vault App Role Credential**
- Scope: Global
- Role ID: REDACTED
- Secret ID: REDACTED
- Path: approle
- Namespace: n/a (a feature of Vault Enterprise)
- ID: vault-jenkins-app-role
- Description: vault-jenkins-app-role

Populate the new Vault Credential then Save. 

The Vault plugin will utilise the `Role ID` and `Secret ID` within this Credential during the `AppRole` backend authentication, to ensure the token issued to Jenkins is associated with the correct `Role` (jenkins-role) and `Policy` (jenkins) we created earlier within Vault.

With the configuration complete, you can now use Vault in your pipeline jobs.

### Create a Test Jenkins Pipeline
We'll test this integration via simple declarative pipelines that authenticate to Vault and consumes a test secret. There are two ways to interact with Vault during our pipeline run; via the `withVault` and `withCredentials` statements.

### withVault
Already built into the Vault plugin as documented here https://www.jenkins.io/doc/pipeline/steps/hashicorp-vault-plugin/

If you need to need to pull out a specific secret for your build, you can use `withVault` to pull the secret and set it to an environment variable. To do so, we'll need some initial blocks to define the `secret` to consume (with the environment variable) and the Vault server `configuration` - example below;

```
def secrets = [
  [path: 'kv1/test', engineVersion: 1, secretValues: [
    [envVar: 'test_kv1', vaultKey: 'mysecret']]],
]

def configuration = [
    vaultUrl: 'https://vault-prd-01.int.leakespeake.com:8200',  
    vaultCredentialId: 'vault-jenkins-app-role', 
    engineVersion: 1
]

pipeline {
    agent any
    ...
```
We then bring these elements together via `withVault` within the step;
```
    stages{   
      stage('Vault') {
        steps {
          withVault([configuration: configuration, vaultSecrets: secrets]) {
            sh "echo ${env.test_kv1}"
          }
```
The other approach is to bind the credential to the variable within Jenkins itself.

### withCredentials
Requires the `Credentials` and `Credentials Binding` plugins (already pre-installed with defaults) - as documented here https://www.jenkins.io/doc/pipeline/steps/credentials-binding/

Using `withCredentials` allows us to bind credentials to variables and requires the setup of a **Vault Secret Text Credential** (per secret) within Jenkins - steps below;

Create a **Vault Secret Text Credential** within *Dashboard > Manage Jenkins > Credentials > System > Global credentials (unrestricted)* - this will define the particular path and key in Vault (for Jenkins) from which to consume the secret value - example;

- Domain: Global credentials (unrestricted)
- **Kind: Vault Secret Text Credential**
- Scope: Global
- Path: kv1/test
- Vault Key: mysecret
- K/V Engine Version: 1
- ID: kv1-test
- Description: kv1-test

Create a pipeline script with a `step` to reference both the ID of the `Vault Secret Text Credential` (kv1-test) and the `variable` name that will be used to load the secret value - in this example MYSECRET1;

```
    stages{   
      stage('Vault Echo Test') {
        steps {
            withCredentials([vaultString(credentialsId: 'kv1-test', variable: 'MYSECRET1')]) {
                sh "echo 'Here you can use the environment variable MYSECRET1'"
            }
          }
        }  
      stage('Vault Curl Test') {
        steps {
            withCredentials([vaultString(credentialsId: 'kv1-test', variable: 'MYSECRET1')]) {
                sh '''
                  curl -X POST -H "Content-Type: application/json" -H "X-Custom-Header: $MYSECRET1" https://vault-prd-01.int.leakespeake.com:8200  
                '''
            }
          }
        }          
    }
```

Create a credential binding between the `Vault Secret Text Credential` and the `Variable` we want to use within the pipeline - in this case MYSECRET1. We do this via the **Pipeline Syntax** link, below our pipeline script definition - example;

- Sample Step: withCredentials: Bind credentials to variables
- Bindings: Vault Secret Text Credential
- Variable: MYSECRET1
- Credentials: kv1/test (kv1-test)
- Generate Pipeline Script

Each binding will define an environment variable active within the scope of the step. The secret value from Vault (as defined in the Vault Secret Text Credential) will be loaded into the MYSECRET1 variable to inject into the pipeline.

After the pipeline run you will see that the secret value has been masked in the builds Console Output;
```
[Pipeline] { (Vault Echo Test)
Masking supported pattern matches of $MYSECRET1

[Pipeline] { (Vault Curl Test)
+ curl -X POST -H Content-Type: application/json -H X-Custom-Header: ****
```

## Chain of Authentication Overview
With so many different elements configured individually, it can be easy to loose track of the chain of events during a pipeline run. A high level overview would be;

JENKINS:
- Jenkins declarative pipeline uses `credentialsId` value `kv1-test` to call the local Jenkins credential (the Vault Secret Text Credential)
- Vault Secret Text Credential with Id `kv1-test` is called - that contains the Vault path and key of the secret value that the pipeline needs - the Vault plugin is then invoked
- The Vault plugin uses the Vault URL `https://vault-prd-01.int.leakespeake.com:8200`and Vault Credential value `vault-jenkins-app-role` (Vault App Role Credential) to initiate authentication to Vault server
- Vault App Role Credential `vault-jenkins-app-role` contains the `Role ID` and `Secret ID` of the Jenkins role `jenkins-role` to authenticate with the AppRole backend on Vault

VAULT:
- Vault AppRole backend is invoked for authentication
- Vault returns a token to the requesting Jenkins server to complete authentication with specific path access defined in the requesters Vault Policy
- The Vault policy `jenkins` (associated with the Jenkins role `jenkins-role`) contains the read and list access to the Vault path and key of the desired secret value, as first called for in the Jenkins declarative pipeline - via the `credentialsId` value
