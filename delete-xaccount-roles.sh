#!/bin/bash
# Filename    : delete-xaccount-roles.sh
# Date        : 12 Jan 2020
# Author      : Tommy Hunt (tahv@pge.com)
# Description : Delete everything created to support and deploy Organiation Config Rules.
#

######################### Delete CodePipeline Deployments
echo Delete the rules in Master account.
aws cloudformation delete-stack --stack-name org-managed-config-rules \
--profile tah

echo Delete the lambdas in Compliance account.
aws cloudformation delete-stack --stack-name omcr-lambda-test \
--profile tahunt

echo Delete the Cross-account roles in Member accounts.
for i in betsy julio thunt tahunt
do
	aws cloudformation delete-stack --stack-name custom-config-xaccount-roles \
	 --profile $i
done

############################ Delete Infrastructure ############################
echo Delete CodePipeline, BuildProjectRole, PipelineRole
aws cloudformation delete-stack --stack-name aws-org-config-rules-pipeline \
--profile betsy

echo Delete the compliance accounts roles
aws cloudformation delete-stack --stack-name toolsacct-codepipeline-cloudformation-role \
--profile tahunt

echo Delete the master accounts roles
aws cloudformation delete-stack --stack-name toolsacct-codepipeline-cloudformation-role \
--profile tah

echo Delete the roles enabling CodeCommit access to CodePipeline
aws cloudformation delete-stack --stack-name toolsacct-codepipeline-role \
--profile thunt

echo Delete the pre-requsites S3, KMS from the Tools account.
aws cloudformation delete-stack --stack-name aws-org-config-rules-pre-reqs \
--profile betsy