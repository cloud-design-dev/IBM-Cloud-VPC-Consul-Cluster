# Deploy a Consul cluster to an IBM Cloud VPC using Terraform and Ansible

## Prerequisites
 - [tfswitch]() installed 
 - [ansible]() installed 
 - An [IBM Cloud API Key]()

## Deploy all resources
1. Clone repository:
    ```sh
    git clone https://github.com/cloud-design-dev/ibm-vpc-consul-terraform-ansible.git
    cd ibm-vpc-consul-terraform-ansible
    ```
1. Copy `terraform.tfvars.template` to `terraform.tfvars`:
   ```sh
   cp terraform.tfvars.template terraform.tfvars
   ```
1. Edit `terraform.tfvars` to match your environment.
1. Run `tfswitch` to point to the right Terraform version for this solution:
   ```
   tfswitch
   ```
1. Deploy all resources:
   ```sh
   terraform init
   terraform plan -out default.tfplan 
   terraform apply default.tfplan
   ```

After the plan completes we will move on to deploying Consul using Ansible. 

## Run Ansible playbook to create the consul cluster
```sh
cd ansible 
ansible-playbook -i inventory playbooks/consul-cluster.yml
```

## Diagram
![Deployment Diagram](consul-cluster-diagram.png)
