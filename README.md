# aws-haproxy-ecs

## Table of Contents
- [What does it do ?](https://github.com/groorj/aws-haproxy-ecs#what-does-it-do)
- [This project uses](https://github.com/groorj/aws-haproxy-ecs#this-project-uses)
- [Notes](https://github.com/groorj/aws-haproxy-ecs#notes)

## What does it do

This project aims to facilitate the creation and deployment of a Docker container with HAProxy on an AWS ECS cluster, incorporating a LoadBalancer for seamless load distribution.

## This project uses / Dependencies

- [HAProxy](https://www.haproxy.org/)
- [Docker](https://www.docker.com/)
- [AWS ECS](https://aws.amazon.com/ecs/)
- [AWS ECR](https://aws.amazon.com/ecr/)
- [AWS cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)


## Install

## Configuration — HAProxy

The HAProxy configuration implemented in this project efficiently handles inbound traffic sourced from a file. It dynamically retrieves the source URI from the HTTP request and matches it against a specified list of URIs, ultimately directing the traffic to the appropriate target destination.

Here is the important portion of the config:

    http-request redirect location %[path,map(/usr/local/etc/haproxy/my_redirect_list.map)]?%[query] code 301 if { path,map(/usr/local/etc/haproxy/my_redirect_list.map) -m found } { query -m found }
    http-request redirect location %[path,map(/usr/local/etc/haproxy/my_redirect_list.map)] code 301 if { path,map(/usr/local/etc/haproxy/my_redirect_list.map) -m found } ! { query -m found }
    http-request redirect location https://github.com/groorj/aws-haproxy-ecs

In case of an unmatched URI, it seamlessly provides a default URL as the designated target.

## Configuration — Docker container

Upon cloning the code, you will have the capability to build the image and execute the container.

Open a terminal or command prompt, navigate to the directory containing the Dockerfile, and run the following command to build the Docker image:

    docker build -t my-haproxy .

Run it locally if you want to test it:

    docker run -d --name my-running-haproxy --sysctl net.ipv4.ip_unprivileged_port_start=0 --publish 8888:8888 --publish 8080:8080 my-haproxy

How to test it:

    curl -vvvvv http://localhost:8080/my-old-path

Result should be:
```
*   Trying 127.0.0.1:8080...
* Connected to localhost (127.0.0.1) port 8080 (#0)
> GET /my-old-path HTTP/1.1
> Host: localhost:8080
> User-Agent: curl/7.86.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 301 Moved Permanently
< content-length: 0
< location: /my-new-path
<
* Connection #0 to host localhost left intact
```

## Configuration — ECR

Log in to the AWS Management Console and navigate to the Amazon ECR service.

Create a new repository or choose an existing one to store your Docker image.

Follow the instructions provided by Amazon ECR to create a repository and obtain the necessary credentials to push images to the repository.

In your terminal or command prompt, authenticate Docker with ECR by running the following command and following the prompts:

    aws ecr get-login-password --region your-ecr-region | docker login --username AWS --password-stdin your-ecr-account-id.dkr.ecr.your-ecr-region.amazonaws.com

*Replace `your-ecr-region` with the AWS region where your ECR repository is located and `your-ecr-account-id` with your AWS account ID.*

Once authenticated, you can push the Docker image that you have created to ECR by running the following command:

    docker tag your-image-name:latest your-ecr-account-id.dkr.ecr.your-ecr-region.amazonaws.com/your-repository-name:latest
    docker push your-ecr-account-id.dkr.ecr.your-ecr-region.amazonaws.com/your-repository-name:latest

*Replace `your-repository-name` with the name of the ECR repository you created or chose.*

> *If you haven't done it yet, you will need to setup your [AWS CLI credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html) in order to be able to push the ECR image.*

## Configuration — ECS

1. Create an ECS cluster:

Log in to the AWS Management Console and navigate to the ECS service.

Create a new cluster or choose an existing one to host your containers.

Follow the instructions provided by ECS to create a cluster.

--> image to cluster creation

--> image to cluster created

2. Create an ECS task definition:

In the ECS service console, navigate to "Task Definitions" and click "Create new Task Definition."
Choose the launch type compatible with your requirements (EC2 or Fargate).

Configure the task definition:
Enter a name for your task definition: `my-haproxy-task-definition`
Specify the task execution role if necessary.

Add a container definition:
Enter a name for your container.
Specify the ECR image URI for your Docker image (e.g., `your-ecr-account-id.dkr.ecr.your-ecr-region.amazonaws.com/your-repository-name:latest`).
Configure the necessary container properties, such as environment variables, port mappings, resource limits, etc.
Review and create the task definition.

Container:
Name: `my-haproxy`
Image URI: `<ECR image>``
Set port `8080` for the haproxy redirect functionality and `8888` for haproxy stats page.

Environment:
App environment: `AWS Fargate`
CPU: `1vCPU`
Memory: `3Gb`
Task role: `None`

3. Create an ECS service:
In the ECS service console, navigate to `Clusters` and select your cluster.
Click `Create` to create a new service.

Configure the service:
Under `Deployment configuration` select `my-haproxy-task-definition` under `Family`.
Under Service name: `my-haproxy-service`
Under `Desired tasks` select 2.
Under `Networking` select your VPC and subnets.
Create a new security group and allow HTTP access to port `80` and TCP access to port `8080`.
Under `Load balacing` select `Application Load Balancer` and then select a name for your Load Balance and a `target group name`.

*You can click `View in CloudFormation` to check the creation of the ECS Service.*

## How to test it

Once the creation is completed, click your the service name you choose under `Services`, then click `Networking`.
There you will find the Load Balancer name under `DNS names`.

How to test it:

    curl -vvvvv http://my-haproxy-ecs-lb-new2-1911689170.us-east-1.elb.amazonaws.com/test


Result should be similar to:
```
*   Trying 54.224.127.10:80...
* Connected to my-haproxy-ecs-lb-new2-1911689170.us-east-1.elb.amazonaws.com (54.224.127.10) port 80 (#0)
> GET /test HTTP/1.1
> Host: my-haproxy-ecs-lb-new2-1911689170.us-east-1.elb.amazonaws.com
> User-Agent: curl/7.86.0
> Accept: */*
>
* Mark bundle as not supporting multiuse
< HTTP/1.1 301 Moved Permanently
< Date: Sat, 01 Jul 2023 18:30:54 GMT
< Content-Length: 0
< Connection: keep-alive
< location: http://test.com
<
* Connection #0 to host my-haproxy-ecs-lb-new2-1911689170.us-east-1.elb.amazonaws.com left intact
```


## Notes

- Congratulations on successfully setting up an AWS ECS cluster that runs a Docker container featuring HAProxy. To ensure efficient load distribution, a Load Balancer has been deployed to handle the traffic.
- Running this code will create AWS resources in your account that might not be included in the free tier.
- Use this code at your own risk, I am not responsible for anything related to its use.
