# Week 7 - OpenTofu on cPouta

This project creates an Ubuntu 24.04 web server on CSC cPouta using OpenTofu.

## Infrastructure

OpenTofu creates:

- SSH key pair
- Security group
- SSH security group rule
- HTTP security group rule
- Network port
- Ubuntu 24.04 VM
- Floating IP

The existing project network is looked up using a data source.

The VM is configured automatically using cloud-init. Apache is installed during the first boot and a custom web page is created.

## Requirements

- OpenTofu
- CSC cPouta project
- OpenStack Application Credential
- SSH key pair

## Configuration

Copy the example variables file:

terraform.tfvars.example


to:

terraform.tfvars


Then set:

- project network
- SSH allowed CIDR
- student name
- page message

The `clouds.yaml` file from cPouta must also be placed in the project directory.

## Deploy

Run:

tofu init tofu fmt tofu validate tofu plan tofu apply


After deployment, get the web page URL with:

tofu output web_url


The VM may need a few minutes for cloud-init to finish.

## Destroy

To remove the resources managed by OpenTofu:

tofu destroy


The existing project network is not removed because it is managed outside this project and is only referenced through a data source.