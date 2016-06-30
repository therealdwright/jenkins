# Jenkins Cloudformation Template

## Overview:
This repository contains a number of components to automatically deploy Jenkins in to a VPC in your own AWS account. Jenkins will run on a Docker Container on an Ubuntu host and will be self-healing. This is achieved by putting the instance in an autoscaling group with a minimum and maximum of 1. Jenkins will back up config, jobs, job history to an S3 bucket in your own account. On failure the autoscaling group will terminate the instance and launch a new one restoring from your latest backup. I take the approach of a S3 lifecycle policy that prunes the backups every 4 days. Doing this lets me restore to a 1 hour RPO at any point over a 2 week period and costs me approximately $5 USD a week.


## Things to do before and after stack creation:
* Specify an SSL certificate in your AWS Account via its ARN.
* Specify an SNS topic with email subscriptions for notifications about Jenkins system metrics (full disk etc).
* Specify the security group ID of a bastion host in your account to allow secure SSH access to the Jenkins instance.
* Specify the VPC you wish to launch the instance in.
* Change the AMI's to ones created yourself using `/packer/packer.json` if you wish to use the Jenkins instance to pull private images.
* Go to CloudWatch logs and open the log stream created by the stack, navigate to the container-logs stream and search the stream for the jenkins initial password.

## Docker components:
I have created a packer install script, you can install Packer on your own machine following the instructions at: https://www.packer.io/downloads.html.

The packer image will create an AMI in your account, and copy it to the regions specified in your file. I have chosen `us-west-1`, `us-west-2` and `ap-southeast-2` for my template. The template in `cloudformation/jenkins.json` will need to be updated to use the AMI's in your account via the region mappings section.

The reason you want to use your own account is I have included a section a file in `packer/config.json` that you can update with your Docker registry token to allow your Jenkins machine to pull private images.

Additionally, the Docker container is configured to use the DOOD (docker outside of docker) configuration. This will allow your Jenkins server to build docker images and run docker-compose unit tests as part of jenkins jobs. More information on the DOOD configuration can be found at: https://github.com/axltxl/docker-jenkins-dood this contains the reference material used to get this up and running.

When you are ready to build the AMI's in your own account, adjust the `packer/config.json` file and execute the command: `packer build packer.json`.

The Dockerfile in this repository is built in a public repository in quay.io.

## AWS components
The Jenkins template comes with a number of components that probably require a bit of further explanation, they are as follows:
* CloudWatch Logs sending a number of metrics to a CloudWatch Log Stream created as part of the template such as:
  * Docker Container Logs sending std out of your Jenkins container to the stream.
  * syslogs containing system information of the Ubuntu host running the container(s).
  * Docker Daemon Logs to view any issues with containers running on your host.
  * CloudFormation cloud-init-output logs so you can view the output of the AutoScaling group userdata.
* CloudWatch custom metrics which are emailed to the addresses in the SNS topic specified in the parameters section. including:
  * EC2 Instance CPU usage.
  * EC2 Instance Memory usage.
  * EC2 Instance disk space usage.
* IAM Role providing the Jenkins instance with **ADMIN ACCESS** to the account it is launched in.
* SSL Certificate is used, please specify a valid IAM SSL Certificate in your account to use the instance with SSH. If you do not wish to do this, though I would not recommend, remove thee SSL certificate parameter and change the ELB listener to use port 80 to your private IP.
* Route 53 record creation is created by you specifying a Route53 zone in your AWS Account, this is updated at the end of the stack creation so you can log in to the Jenkins instance using this.

## Credit
This template has used a lot of the concepts from the repository at https://github.com/thefactory/cloudformation-jenkins I'm unsure if this repository is still being maintained. I've used some of their concepts but built this template out using a lot of the things I felt were missing. Big thanks to The Factory, they were very useful when I started exploring the path of automating Jenkins.
