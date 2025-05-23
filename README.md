# aws-cli-infra-setup

## Goal
Create a secure AWS infrastructure using the AWS CLI
### Infrastructure Requirements:
- VPC:
  - Must support at least 50 Private IPs and 10 Public IPs.

  - Choose a suitable CIDR block and create subnets accordingly (public & private).


- EC2 Instances:
  - 1 Public Instance with internet access.
  - 1 Private Instance that must be able to get updates via NAT or a similar solution.
  - Both instances should allow SSH access for maintenance.
  - Install the latest system updates as part of the launch process.

## Benefit
This Projects provides you with a shell script thatallows you to quickly set up a simple awsinfrastructure. The project name can be set uponexecution and influences the names of most subcomponents.

## Useage
You can clone this repository with the git command:
```
git clone git@github.com:Axel-ITT/aws-cli-infra-setup.git
```
To use this script you need to:
 1. Make sure your aws cli credentials are up to date
 2. Make sure the script permissions allow it to be executed
 3. Execute the script:
 ```
.[/pathToScriptDirectory]/create-baseline-infrastructure.sh
 ```
