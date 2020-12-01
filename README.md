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

## Verify that the cluster is running
Since we bound the Consul agent to the main private IP of the VPC instances we first need to set the environmental variable for CONSUL_HTTP_ADDR. Take one of the consul instance IPs and run the following command:

```shell
ansible -m shell -b -a "CONSUL_HTTP_ADDR=\"http://CONSUL_INSTANCE_IP:8500\" consul members" CONSUL_INSTANCE_NAME -i inventory
```

### Example output
```shell
ansible -m shell -b -a "CONSUL_HTTP_ADDR=\"http://10.241.0.36:8500\" consul members" dev-011534-us-east-1-consul1 -i inventory
dev-011534-us-east-1-consul1 | CHANGED | rc=0 >>

Node                          Address           Status  Type    Build  Protocol  DC       Segment
dev-011534-us-east-1-consul1  10.241.0.36:8301  alive   server  1.9.0  2         us-east  <all>
dev-011534-us-east-1-consul2  10.241.0.38:8301  alive   server  1.9.0  2         us-east  <all>
dev-011534-us-east-1-consul3  10.241.0.37:8301  alive   server  1.9.0  2         us-east  <all>
```

### Asciinema recording 
[![asciicast](https://asciinema.org/a/376553.svg)](https://asciinema.org/a/376553)


## Diagram
![Deployment Diagram](consul-cluster-diagram.png)
