# Overview

**Major reqwrite in progress**

I am on the process of updating this example to use IBM Cloud Terraform modules as well as using ACLs to further segment the network. This guide will also be updated to use Packer to create a custom image with Consul installed. (this keeps us form having to open traffic on the backend ACL to the internet to grab the Consul apt key and binary)

## Diagram

![Base diagram of ACLs and SGs](./vpc-acl-sg.png)

## Test results

```shell
$ ansible -m shell -b -a "consul members" tpa-v2-instance-1 -i ansible/inventory       
tpa-v2-instance-1 | CHANGED | rc=0 >>
Node               Address          Status  Type    Build   Protocol  DC       Partition  Segment
tpa-v2-instance-0  10.241.0.7:8301  alive   server  1.15.0  2         us-east  default    <all>
tpa-v2-instance-1  10.241.0.5:8301  alive   server  1.15.0  2         us-east  default    <all>
tpa-v2-instance-2  10.241.0.8:8301  alive   server  1.15.0  2         us-east  default    <all>
```

Now I just need to write up the guide ... 
