# AWS Deployments

General information for deploying onto the AWS provider.

___

# **SSH**

Amazon EC2 uses public key cryptography to encrypt and decrypt login information - via a _key pair_;

- **public key**	(encrypt the data)
- **private key**	(decrypt the data)	(**.pem** - OpenSSH format / **.ppk** - Putty format)

Amazon EC2 stores the public key only - you store the private key locally. The keys that Amazon EC2 uses are 2048-bit SSH-2 RSA keys. 

First, we create our key pair.

___

**OpenSSH (ssh-keygen)**

Launch Git Bash and ensure no keys are currently added to the SSH agent - we should see "The agent has no identities";

```
ssh-add -L
```

Use the ssh-keygen tool to create our key pair;

```
ssh-keygen -t rsa -b 2048
```

set key location as:		/c/Users/username/.ssh/EC2/id_rsa

Enter passphrase:		    Enter (blank)

Enter passphrase:		    Enter (blank)

We finish with;

~/.ssh/EC2/id_rsa		    (private key - must rename to .pem)
~/.ssh/EC2/id_rsa.pub		(public key - for upload to AWS)

Rename id_rsa to id_rsa.pem

Lastly, make id_rsa.pem read-only via; 

```
sudo chmod 400 /c/Users/username/.ssh/EC2/id_rsa.pem
```

___

**Terraform**

When you launch an EC2 instance, you specify the key pair. At boot time, the public key content is placed on the instance in an entry within **~/.ssh/authorized_keys**

Each key pair requires a name. Amazon EC2 associates the public key with the name that you specify as the key name. In Terraform we specify this in the 'key_name' argument;

```
resource "aws_instance" "ssh-example" {
    ami                     = "ami-0c55b159cbfafe1f0"
    instance_type           = "t2.micro"
    key_name                = "dem-keys-2020"
```

We can then either upload the key pair's public key to AWS > EC2 > Key Pairs (matching the 'key_name' value in the EC2 resource) - OR - specify the EC2 key pair via the 'aws_key_pair' resource;

```
resource "aws_key_pair" "dem-keys-2020" {
  key_name   = "dem-keys-2020"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAp1ejXSrbX8ZbabVohBK41etc email@example.com"
}
```

Make sure you tighten the SSH **ingress** rule to only allow connections from known CIDR blocks. You may also need to add an allow all **egress** rule for the return traffic.

Once deployed, we can test.

___

**Testing the connection**

Ensure you have the correct username for the AMI you have deployed (either set yourself via a Packer template - OR - search the public AMI's in the EC2 console by region) - in this example it's **ubuntu**

You must also specify the local private key associated with the EC2 instance public key (within **~/.ssh/authorized_keys**)

```
ssh -i ~/.ssh/EC2/id_rsa.pem -v ubuntu@ec2-3-15-163-63.us-east-2.compute.amazonaws.com

ssh -i ~/.ssh/EC2/id_rsa.pem ubuntu@ec2-3-21-165-238.us-east-2.compute.amazonaws.com lsb_release -a
```

___

**Key pair tests**

We can use the following to verify that the private key you have on your local machine matches the public key stored in AWS - by comparing the fingerprint;

```
ssh-keygen -ef /c/Users/username/.ssh/EC2/id_rsa.pem -m PEM | openssl rsa -RSAPublicKey_in -outform DER | openssl md5 -c
```

We can also retrieve the public key from the private file;

```
ssh-keygen -y -f /c/Users/username/.ssh/EC2/id_rsa.pem
```

The output should match the 'public_key' value used in the aws_key_pair resource.