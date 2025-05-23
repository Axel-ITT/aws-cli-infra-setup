#!/bin/bash
#AWS VPC Setup
echo "What is the name of your Project?"
read projectName
export projectName
# Create vpc
export vpcId=$(aws ec2 create-vpc --cidr-block 10.0.0.0/25 --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=$projectName-vpc}]" | grep -e "VpcId" | sed 's/"VpcId": "//' | sed 's/",//' | tr -d ' ')
echo "VPC created with ID: $vpcId and Name: $projectName-vpc"
# Create subnets
export privateSubId=$(aws ec2 create-subnet --availability-zone us-west-2b --cidr-block 10.0.0.0/26 --vpc-id $vpcId --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$projectName-private-sub}]" | grep -e "SubnetId" | sed 's/"SubnetId": "//' | sed 's/",//' | tr -d ' ')
echo "Private Subnet created with ID: $privateSubId and Name: $projectName-private-sub"
export publicSubId=$(aws ec2 create-subnet --availability-zone us-west-2b --cidr-block 10.0.0.64/28 --vpc-id $vpcId --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$projectName-public-sub}]" | grep -e "SubnetId" | sed 's/"SubnetId": "//' | sed 's/",//' | tr -d ' ')
echo "Public Subnet created with ID: $publicSubId and Name: $projectName-public-sub"
# Create and attach internet gateway
export igwId=$(aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=$projectName-igw}]" | grep -e "InternetGatewayId" | sed 's/"InternetGatewayId": "//' | sed 's/",//' | tr -d ' ')
echo "Internet Gateway created with ID: $igwId and Name: $projectName-igw"
aws ec2 attach-internet-gateway --internet-gateway-id $igwId --vpc-id $vpcId
echo "Internet Gateway attached to VPC"
# Create and attach route table
export routeTableId=$(aws ec2 create-route-table --vpc-id $vpcId | grep -e "RouteTableId" | sed 's/"RouteTableId": "//' | sed 's/",//' | tr -d ' ')
echo "RouteTable created with ID: $routeTableId"
export associationId=$(aws ec2 associate-route-table --route-table-id $routeTableId --subnet-id $publicSubId | grep -e "AssociationId" | sed 's/"AssociationId": "//' | sed 's/",//' | tr -d ' ')
echo "Route Table Association was created with ID: $associationId"
# Create route
export routeOutput=$(aws ec2 create-route --route-table-id $routeTableId --destination-cidr-block 0.0.0.0/0 --gateway-id $igwId)
echo "Route was created: $routeOutput"
# Creat NAT-gateway inside public subnet
export elasticId=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)
echo "Elastic IP: $elasticId was created"
export natId=$(aws ec2 create-nat-gateway --subnet-id $publicSubId --allocation-id $elasticId --query 'NatGateway.NatGatewayId' --output text)
echo "NAT-Gateway: $natId was created"
#
#
#AWS EC2 Setup
# Linux 2 ami
export amiId="ami-0ec1ab28d37d960a9"
export myIP=$(curl -s https://checkip.amazonaws.com)
# Create public security group
export pubSGId=$(aws ec2 create-security-group \
    --group-name $projectName-publicSG \
    --description "My public security group" \
    --vpc-id $vpcId \
    --query 'GroupId' \
    --output text
    )
echo "Public security group allows:"
# Allow all outbound in pubSG (default on creation)
echo "- outbound: ALL Traffic ALL IP"
# Allow ssh in pubSG
aws ec2 authorize-security-group-ingress \
  --group-id $pubSGId \
  --protocol tcp \
  --port 22 \
  --cidr $myIP/32\
  > /dev/null
echo "- inbound: SSH from $myIP/32"
# Allow HTTP in pubSG
aws ec2 authorize-security-group-ingress \
  --group-id $pubSGId \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0\
  > /dev/null
echo "- inbound: HTTP from ALL IP"
# Allow HTTPS in pubSG
aws ec2 authorize-security-group-ingress \
  --group-id $pubSGId \
  --protocol tcp \
  --port 443 \
  --cidr 0.0.0.0/0\
  > /dev/null
echo "- inbound: HTTPS from ALL IP"
#
# Create private security group
export privSGId=$(aws ec2 create-security-group \
    --group-name $projectName-privateSG \
    --description "My private security group" \
    --vpc-id $vpcId \
    --query 'GroupId' \
    --output text
    )
# Allow all outbound in pubSG (default on creation)
echo "- outbound: ALL Traffic ALL IP"
# Allow ssh in privSG
aws ec2 authorize-security-group-ingress \
  --group-id $privSGId \
  --protocol tcp \
  --port 22 \
  --cidr $myIP/32 \
  > /dev/null
echo "- inbound: SSH from $myIP/32"
# Create public instance
export pubEc2Id=$(aws ec2 run-instances \
    --image-id $amiId \
    --instance-type t2.micro \
    --key-name vockey \
    --security-group-ids $pubSGId \
    --subnet-id $publicSubId \
    --user-data file://user-data/update-linux2-instance.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$projectName-public-instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)
echo "Instance created with ID: $pubEc2Id and Name: $projectName-public-instance"
# Create private instance
export privEc2Id=$(aws ec2 run-instances \
    --image-id $amiId \
    --instance-type t2.micro \
    --key-name vockey \
    --security-group-ids $privSGId \
    --subnet-id $privateSubId \
    --user-data file://user-data/update-linux2-instance.sh \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$projectName-private-instance}]" \
    --query 'Instances[0].InstanceId' \
    --output text)
echo "Instance created with ID: $privEc2Id and Name: $projectName-private-instance"

## ToDo Assign public ip to public server on creation
## ToDo ssh to private server not possible maybe allow connection from public sub?
## ToDo check if more security is possible and add it to script
## Seperate into smaller sub scripts for readability? need to preserve environment variable values
## export wasnt enough
