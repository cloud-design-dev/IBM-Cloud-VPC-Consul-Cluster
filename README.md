# Overview

**Major reqwrite in progress**

I am on the process of updating this example to use IBM Cloud Terraform modules as well as using ACLs to further segment the network. This guide will also be updated to use Packer to create a custom image with Consul installed. (this keeps us form having to open traffic on the backend ACL to the internet to grab the Consul apt key and binary)

- [ ] Include packer to create custom image with Consul installed - https://registry.terraform.io/providers/toowoxx/packer/latest

## Diagram

 > Note: This diagram is out of date. I will update it soon to include Packer and the updated ACLs.

![Deployment Diagram](consul-cluster-diagram.png)


## Tasks
### target-dev-account
Target IBM Cloud Testing account

```
ibmcloud logout -q > /dev/null 2>&1
unset IBMCLOUD_API_KEY
export IBMCLOUD_API_KEY=$(jq -r .apikey ~/Sync/SynologyDrive/Systems/api-keys/dev-account-ibmcloud-apikey.json) 
ibmcloud login -r us-south -q > /dev/null 2>&1
```

### target-cde-account
Target IBM Cloud CDE Account

```
unset IBMCLOUD_API_KEY
export IBMCLOUD_API_KEY=$(scrt get ibmcloud_api_key)
ibmcloud login -r us-south -g CDE -q > /dev/null 2>&1
```

### tf-reset
Reset Terraform directory

```
rm -rf .terraform .terraform.lock.hcl
rm -f *.tfplan
```

### tf-dev-init
Run Terraform init and upgrade

```
unset IBMCLOUD_API_KEY
export IBMCLOUD_API_KEY=$(jq -r .apikey ~/Sync/SynologyDrive/Systems/api-keys/dev-account-ibmcloud-apikey.json) 

terraform fmt --recursive
terraform init -upgrade=true
terraform validate
```

### tf-dev-run 
Run Terraform plan and save to file

```
unset IBMCLOUD_API_KEY
export IBMCLOUD_API_KEY=$(jq -r .apikey ~/Sync/SynologyDrive/Systems/api-keys/dev-account-ibmcloud-apikey.json) 

terraform plan -out "$(terraform workspace show).tfplan"
terraform apply "$(terraform workspace show).tfplan"
```