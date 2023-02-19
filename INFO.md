### old guide
The following code will deploy a 3 node [Consul](https://www.consul.io/) cluster in a single IBM Cloud [VPC zone](https://cloud.ibm.com/docs/vpc?topic=vpc-about-networking-for-vpc#networking-terms-zones). If you do not already have an available VPC the code can create one for you. You will then use Ansible to install and configure Consul on the compute instances. 

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->

- [Prerequisites for **all** deployment options](#prerequisites-for-all-deployment-options)
  - [Prerequisites for Deployment Option 1: Local Terraform deployment](#prerequisites-for-deployment-option-1-local-terraform-deployment)
  - [Prerequisites for Deployment Option 2: Local bxshell deployment](#prerequisites-for-deployment-option-2-local-bxshell-deployment)
- [Generate Consul Encrypt Key](#generate-consul-encrypt-key)
- [Deploy all resources](#deploy-all-resources)
  - [Inputs](#inputs)
  - [Outputs](#outputs)
- [Run Ansible playbook to create the consul cluster](#run-ansible-playbook-to-create-the-consul-cluster)
- [Verify that the cluster is running](#verify-that-the-cluster-is-running)
  - [Example output](#example-output)
  - [Asciinema recording](#asciinema-recording)
- [Diagram](#diagram)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->


## Prerequisites for **all** deployment options
The following information will be needed for each of the deployment options.  

 - An [IBM Cloud API Key](https://cloud.ibm.com/docs/account?topic=account-userapikey#create_user_key)
 - A Consul [Encrypt Key](https://www.consul.io/docs/agent/options#_encrypt). This is the secret key to use for encryption of Consul network traffic. See [Generate Consul Encrypt Key](#generate-consul-encrypt-key) for running the `keygen` command.
 - [Docker](https://docs.docker.com/get-docker/) installed. We will use a Consul Docker image to generate our Consul Encrypt key.
 - 
### Prerequisites for Deployment Option 1: Local Terraform deployment
In addition to the [above](#prerequisites-for-all-deployment-options), the following resources are required to deploy using a local terraform installation:

 - [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) installed. This will deploy the required infrastructure.
 - [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html#installing-ansible-on-specific-operating-systems) installed. This will configure our Consul instances.  
 - [tfswitch](https://tfswitch.warrensbox.com/Install/) installed. 

### Prerequisites for Deployment Option 2: Local bxshell deployment 
If you would like to use an IBM Cloud friendly Docker image in order to not interfere with locally installed versions of the required tools, I recommend using [bxshell](https://github.com/l2fprod/bxshell). In addition to the [above](#prerequisites-for-all-deployment-options), the following resources are required to deploy using bxshell

 - [bxshell](https://github.com/l2fprod/bxshell#install) installed. 

## Generate Consul Encrypt Key
If you have [Docker](https://docs.docker.com/get-docker/) installed run the following command to generate the `encrypt_key`

```sh
docker run -it consul:latest consul keygen
```

## Deploy all resources
1. Clone repository:
    ```sh
    git clone https://github.com/cloud-design-dev/IBM-Cloud-VPC-Consul-Cluster.git
    cd IBM-Cloud-VPC-Consul-Cluster
    ```
1. Copy `terraform.tfvars.template` to `terraform.tfvars`:
   ```sh
   cp terraform.tfvars.template terraform.tfvars
   ```
1. Edit `terraform.tfvars` to match your environment. See [Inputs](#inputs) for description of options.

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

After the plan completes we will move on to [deploying Consul using Ansible](#run-ansible-playbook-to-create-the-consul-cluster). 

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| ibmcloud\_api\_key | IBM Cloud API key to use for deploying resources. | `string` | n/a | yes |
| name | Name that will be prepended to all resources. | `string` | n/a | yes |
| region | Name of the IBM Cloud region where resources will be deployed. Run `ibmcloud is regions` to see available options. | `string` | n/a | yes |
| owner | Identifier for the user that created the VPC and cluster. | `string` | n/a | yes |
| ssh\_key | Name of an existing ssh key that will be added to the vpn instance. | `string` | n/a | yes |
| existing\_resource\_group | The name of an existing Resource group to use. If none provided, a new one will be created. | `string` | n/a | no | 
| existing\_vpc\_name | The name of an existing VPC to use for deployed resources. If none provided, one will be created for you. If you use an existing VPC you must also specify `existing_subnet_name` | `string` | `n/a` | no |
| existing\_subnet\_name | The name of an existing Subnet to use for deployed resources. If none provided, one will be created for you. If you use an existing Subnet you must also specify `existing_vpc_name`. | `string` | `n/a` | no |
| allow\_ssh\_from | An IP Address, CIDR block, or VPC Security group that will be allowed to access the bastion via SSH. | `string` | `0.0.0.0/0` | no | 
| tags | Tags to add to all deployed resources | `list(string)` | `[]` | no |
| profile | Instance size for compute nodes. Run `ibmcloud is in-prs` to see available options. | `string` | `cx2-2x4` | no |
| image | Default OS image to use for Consul nodes size for compute nodes. Run `ibmcloud is images` to see available options. | `string` | `ibm-ubuntu-20-04-minimal-amd64-2` | no |

### Outputs
| Name | Description | 
|------|-------------|
| bastion\_public\_ip | Public IP of our bastion instance. |
| consul\_instance\_ips | Private IPs for the consul nodes. |
| consul\_instance\_names | The names of the consul instances |
## Run Ansible playbook to create the consul cluster
With the consul nodes deployed we will now move in to creating our cluster. 

```sh
❯ cd ansible 
❯ ansible-playbook -i inventory playbooks/consul-cluster.yml
```

## Verify that the cluster is running
Run the following command to verify the cluster is running. `CONSUL_INSTANCE_NAME` is the name of one of the consul instances in your inventory file. 

```shell
❯ ansible -m shell -b -a "consul members" CONSUL_INSTANCE_NAME -i inventory
```

### Example output
```shell
❯ ansible -m shell -b -a "consul members" consulrt-consul1 -i inventory
consulrt-consul1 | CHANGED | rc=0 >>
Node              Address          Status  Type    Build  Protocol  DC       Segment
consulrt-consul1  10.241.0.4:8301  alive   server  1.9.6  2         us-east  <all>
consulrt-consul2  10.241.0.5:8301  alive   server  1.9.6  2         us-east  <all>
consulrt-consul3  10.241.0.6:8301  alive   server  1.9.6  2         us-east  <all>
```
