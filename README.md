## sparkleformation-indigo-rds
This repository contains SparkleFormation templates that create RDS instances.

SparkleFormation is a tool that creates CloudFormation templates, which are
static documents declaring resources for AWS to create.

### Dependencies

The template requires external Sparkle Pack gems, which are noted in
the Gemfile and the .sfn file.  These gems interact with AWS through the
`aws-sdk-core` gem to identify or create  availability zones, subnets, and 
security groups.

### Empire-RDS Parameters

When launching the compiled CloudFormation template, you will be prompted for
some stack parameters:

TODO...

| Parameter | Default Value | Purpose |
|-----------|---------------|---------|
| AllowSshFrom | 127.0.0.1/32 | Governs SSH access to the NAT instance.  Setting to 127.0.0.1/32 effectively disables SSH accesss. |
| CidrPrefix | 16 | The CIDR prefix will be the second octet of the VPC's addrange range.  e.g. 172.16.0.0/16 |
| EnableDnsHostnames | true | Just leave it set to true |
| EnableDnsSupport | true | Just leave it set to true |
| HostedZoneName | variable | `ENV['environment']`.`ENV['organization']` e.g. dev.indigo | 
| InstanceTenancy | default | Just leave it set to default |
| NatInstancesInstanceType | t2.small | Larger instances have more network capacity.  Valid values are t2.small, t2.medium, m3.large, and c4.large |
| SshKeyPair | indigo-bootstrap | An SSH key pair for use when logging into the NAT instance.  Log in as the 'ec2-user' account. |
| VpcName	| variable | `ENV['organization']`-`ENV['environment']`-`ENV['AWS_REGION']`-vpc |

