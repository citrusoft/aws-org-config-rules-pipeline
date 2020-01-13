#!/bin/bash
# Filename    : deploy-xaccount-roles.sh
# Date        : 10 Jan 2020
# Author      : Tommy Hunt (tahv@pge.com)
# Description : Deploys Cross-account roles that allow OrganizationConfigRule, VPCFlowLogS3Enforcement, 
#               to detect, correct and report non-compliant VPC FlowLogging.
#
echo Cross-account roles in ToolAccount
aws cloudformation deploy --stack-name custom-config-xaccount-roles \
 --template-file MemberAccount/01-custom-config-xaccount-roles.yaml \
 --capabilities CAPABILITY_NAMED_IAM \
 --profile betsy
echo Cross-account roles in MemberAccount
aws cloudformation deploy --stack-name custom-config-xaccount-roles \
 --template-file MemberAccount/01-custom-config-xaccount-roles.yaml \
 --capabilities CAPABILITY_NAMED_IAM \
 --profile julio
echo Cross-account roles in DevAccount
aws cloudformation deploy --stack-name custom-config-xaccount-roles \
 --template-file MemberAccount/01-custom-config-xaccount-roles.yaml \
 --capabilities CAPABILITY_NAMED_IAM \
 --profile thunt
echo Cross-account roles in ComplianceAccount
aws cloudformation deploy --stack-name custom-config-xaccount-roles \
 --template-file MemberAccount/01-custom-config-xaccount-roles.yaml \
 --capabilities CAPABILITY_NAMED_IAM \
 --profile tahunt
