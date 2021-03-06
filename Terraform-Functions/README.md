# Terraform Console

Terraform comes with lots of functions (built into the binary) and often you might be unsure of how they work. Luckily, you can use a combination of **terraform console** and local values to test out every function available - see https://www.terraform.io/docs/language/functions/index.html

Terraform has three different kinds of variables;

- **input** variables which serve as parameters in Terraform modules

- **output** values that are returned to the user at **terraform apply** and can be queried using **terraform output** (any time after the apply)

- **local** values assign a name to an expression so you can use it multiple times within a module without repeating - such as **local.node_count** to set the same 'count' value for each resource in the module

We will utilize a **locals {}** block to state some local variables that we can run the functions against. This is a good way to test the operability before adding it into your working modules.

## Using the Terraform Console to test 

Create main.tf and populate with the local variables

Use the VSC **TERMINAL** to cd to the directory of main.tf

Initialize it for Terraform use via 'tf init'

Run the **terraform console** command to drop into the console

---

