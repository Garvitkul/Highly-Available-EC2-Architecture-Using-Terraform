# Highly Available EC2 Architecture Using Terraform

1. **VPC (Virtual Private Cloud)**:
   - A VPC is created with a CIDR block of `10.0.0.0/16`. It provides network isolation for the resources within the environment.

2. **Internet Gateway**:
   - An internet gateway is attached to the VPC to allow communication between instances in the VPC and the internet.

3. **Subnets**:
   - Two public subnets are created in different availability zones (`us-east-1a` and `us-east-1b`).
   - These subnets allow instances within them to have public IP addresses and communicate with the internet.

4. **Route Table**:
   - A route table is created and associated with the public subnets.
   - It includes a route to the internet gateway to enable internet access for resources within the VPC.

5. **Security Group**:
   - A security group named "hyperverge-autoscaling-sg" is created.
   - It allows inbound traffic on port 80 (HTTP) from any IP address and all outbound traffic.

6. **Key Pair**:
   - An SSH key pair named "hyperverge-key" is created for accessing EC2 instances securely.

7. **Launch Configuration**:
   - A launch configuration named "hyperverge-lc" is created.
   - It specifies the configuration for launching EC2 instances, including instance type, AMI, user data, and security groups.

8. **Autoscaling Group**:
   - An autoscaling group named "hyperverge-asg" is created.
   - It automatically adjusts the number of EC2 instances based on demand.
   - The autoscaling group uses the launch configuration and is spread across multiple availability zones.

9. **ALB (Application Load Balancer)**:
   - An ALB named "hyperverge-lb" is created.
   - It distributes incoming HTTP traffic across multiple EC2 instances for scalability and fault tolerance.

10. **Target Group**:
    - A target group named "hyperverge-tg" is created.
    - It defines a group of EC2 instances that can receive traffic from the ALB.
    - Health checks are configured to monitor the health of instances.

11. **Autoscaling Attachments**:
    - Autoscaling attachments associate the autoscaling group with the target group.
    - They ensure that instances launched by the autoscaling group are registered with the target group for load balancing.

**Architecture Insight**:
- The architecture follows best practices for high availability and scalability.
- Instances are launched in multiple availability zones for fault tolerance.
- An ALB distributes incoming traffic evenly across instances in the autoscaling group.
- Autoscaling automatically adjusts the number of instances based on demand, ensuring optimal performance and cost efficiency.
- Security groups control inbound and outbound traffic to the instances.
- Overall, this architecture provides a resilient and scalable infrastructure for hosting web applications or services.

**Make sure to have your AWS Access Keys and Secret Keys ready.**
__________________________________________________________________________
Steps to create AWS infrastructure using Terraform -
1. Install Terraform
2. Craate a directory **HyperVerge**
3. Now create main.tf and variables.tf files and copy content to the files respectively.
4. Now run Terraform init
5. Run Terraform validate to make sure that script has no issues.
6. Run Terraform apply
7. Provide credentials.
8. Your AWS infrastructure is created.
Make sure to destroy everything if not in use using Terraform destroy command.

__________________________________________________________________________

**There is one issue with this Terraform script -**
Due to new IMDSv2 settings in AWS EC2 servers, it is not allowing to fetch instance details using http://169.254.169.254/latest/meta-data/.
I tried to set up IMDS as IMDSv1 instead of IMDSv2 but it did not work. I just configured this setting manually to **set IMDSv2 as optional.**

__________________________________________________________________________
**Screenshot of the resources created**
![image](https://github.com/Garvitkul/Highly-Available-EC2-Architecture-Using-Terraform/assets/83578615/0682de35-003f-45d9-88b1-628bbfb1e547)
![image](https://github.com/Garvitkul/Highly-Available-EC2-Architecture-Using-Terraform/assets/83578615/0e8fdad6-059b-4704-8580-c3f06c0a7c9f)
![image](https://github.com/Garvitkul/Highly-Available-EC2-Architecture-Using-Terraform/assets/83578615/8ea67670-77f5-471c-86c9-6a6580c2aaa4)
![image](https://github.com/Garvitkul/Highly-Available-EC2-Architecture-Using-Terraform/assets/83578615/5ceb9997-8c3b-4fca-bf1c-b9e0470722f0)
![image](https://github.com/Garvitkul/Highly-Available-EC2-Architecture-Using-Terraform/assets/83578615/e6f980d6-4451-48c9-a182-59bdf88bdf66)
![image](https://github.com/Garvitkul/Highly-Available-EC2-Architecture-Using-Terraform/assets/83578615/39b1f180-3ec8-441f-9401-cd40e0a78a51)


