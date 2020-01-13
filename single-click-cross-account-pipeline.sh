#!/usr/bin/env bash
default=782391863272
read -p "Enter ToolsAccount [$default]> " ToolsAccount
ToolsAccount=${ToolsAccount:-$default}
echo ToolsAccount=$ToolsAccount
default=betsy
read -p "Enter ToolsAccount ProfileName for AWS Cli operations [$default]> " ToolsAccountProfile
ToolsAccountProfile=${ToolsAccountProfile:-$default}
echo ToolsAccountProfile=$ToolsAccountProfile
default=123133550781
read -p "Enter Dev Account [$default]> " DevAccount
DevAccount=${DevAccount:-$default}
echo DevAccount=$DevAccount
default=thunt
read -p "Enter DevAccount ProfileName for AWS Cli operations [$default]> " DevAccountProfile
DevAccountProfile=${DevAccountProfile:-$default}
echo DevAccountProfile=$DevAccountProfile
default=567207295412
read -p "Enter ComplianceAccount [$default]> " ComplianceAccount
ComplianceAccount=${ComplianceAccount:-$default}
echo ComplianceAccount=$ComplianceAccount
default=tahunt
read -p "Enter ComplianceAccount ProfileName for AWS Cli operations [$default]> " ComplianceAccountProfile
ComplianceAccountProfile=${ComplianceAccountProfile:-$default}
echo ComplianceAccountProfile=$ComplianceAccountProfile
default=919568423267
read -p "Enter Master Account [$default]> " MasterAccount
MasterAccount=${MasterAccount:-$default}
echo MasterAccount=$MasterAccount
default=tah
read -p "Enter MasterAccount ProfileName for AWS Cli operations [$default]> " MasterAccountProfile
MasterAccountProfile=${MasterAccountProfile:-$default}
echo MasterAccountProfile=$MasterAccountProfile

aws cloudformation deploy --stack-name pre-reqs \
--template-file ToolsAcct/pre-reqs.yaml \
--parameter-overrides DevAccount=$DevAccount ComplianceAccount=$ComplianceAccount ProductionAccount=$MasterAccount \
--profile $ToolsAccountProfile

echo -n "Enter S3 Bucket created from above > "
read S3Bucket

echo -n "Enter CMK ARN created from above > "
read CMKArn

echo -n "Executing in DEV Account"
aws cloudformation deploy --stack-name toolsacct-codepipeline-role \
--template-file DevAccount/toolsacct-codepipeline-codecommit.yaml \
--capabilities CAPABILITY_NAMED_IAM \
--parameter-overrides ToolsAccount=$ToolsAccount CMKARN=$CMKArn \
--profile $DevAccountProfile

echo -n "Executing in Compliance Account"
aws cloudformation deploy --stack-name toolsacct-codepipeline-cloudformation-role \
--template-file ComplianceAccount/toolsacct-codepipeline-cloudformation-deployer.yaml \
--capabilities CAPABILITY_NAMED_IAM \
--parameter-overrides MasterAccount=$MasterAccount ToolsAccount=$ToolsAccount CMKARN=$CMKArn  S3Bucket=$S3Bucket \
--profile $ComplianceAccountProfile

echo -n "Executing in Master Account"
aws cloudformation deploy --stack-name toolsacct-codepipeline-cloudformation-role \
--template-file MasterAccount/toolsacct-codepipeline-cloudformation-deployer.yaml \
--capabilities CAPABILITY_NAMED_IAM \
--parameter-overrides ToolsAccount=$ToolsAccount CMKARN=$CMKArn  S3Bucket=$S3Bucket \
--profile $MasterAccountProfile

echo -n "Creating Pipeline in Tools Account"
aws cloudformation deploy --stack-name sample-lambda-pipeline \
--template-file ToolsAcct/code-pipeline.yaml \
--parameter-overrides DevAccount=$DevAccount ComplianceAccount=$ComplianceAccount MasterAccount=$MasterAccount CMKARN=$CMKArn S3Bucket=$S3Bucket --capabilities CAPABILITY_NAMED_IAM \
--capabilities CAPABILITY_NAMED_IAM \
--profile $ToolsAccountProfile

echo "********* Adding Cross Account Roles to Memeber Accounts"
./deploy-xaccount-roles.sh

echo -n "Adding Permissions to the CMK"
aws cloudformation deploy --stack-name pre-reqs \
--template-file ToolsAcct/pre-reqs.yaml \
--parameter-overrides CodeBuildCondition=true \
--profile $ToolsAccountProfile

echo -n "Adding Permissions to the Cross Accounts"
aws cloudformation deploy --stack-name sample-lambda-pipeline \
--template-file ToolsAcct/code-pipeline.yaml \
--parameter-overrides CrossAccountCondition=true \
--capabilities CAPABILITY_NAMED_IAM \
--profile $ToolsAccountProfile
