#!/usr/bin/env bash

if [ "$1" = "-B" ]; then
  batch=true
else
  batch=false
fi

# This is a general-purpose function to ask Yes/No questions in Bash, either
# with or without a default answer. It keeps repeating the question until it
# gets a valid answer.

ask() {
    local prompt default reply

    if [ "${2:-}" = "Y" ]; then
        prompt="Y/n"
        default=Y
    elif [ "${2:-}" = "N" ]; then
        prompt="y/N"
        default=N
    else
        prompt="y/n"
        default=
    fi

    while true; do

        # Ask the question (not using "read -p" as it uses stderr not stdout)
        echo -n "$1 [$prompt] "

        # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
        read reply </dev/tty

        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi

        # Check if the reply is valid
        case "$reply" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac

    done
}

if $batch ; then
	ToolsAccount=782391863272
	ToolsAccountProfile=betsy
	DevAccount=123133550781
	DevAccountProfile=thunt
	ComplianceAccount=567207295412
	ComplianceAccountProfile=tahunt
	MasterAccount=919568423267
	MasterAccountProfile=tah
else
	default=782391863272
	read -p "Enter ToolsAccount [$default]> " ToolsAccount
	ToolsAccount=${ToolsAccount:-$default}
	default=betsy
	read -p "Enter ToolsAccount ProfileName for AWS Cli operations [$default]> " ToolsAccountProfile
	ToolsAccountProfile=${ToolsAccountProfile:-$default}
	default=123133550781
	read -p "Enter Dev Account [$default]> " DevAccount
	DevAccount=${DevAccount:-$default}
	default=thunt
	read -p "Enter DevAccount ProfileName for AWS Cli operations [$default]> " DevAccountProfile
	DevAccountProfile=${DevAccountProfile:-$default}
	default=567207295412
	read -p "Enter ComplianceAccount [$default]> " ComplianceAccount
	ComplianceAccount=${ComplianceAccount:-$default}
	default=tahunt
	read -p "Enter ComplianceAccount ProfileName for AWS Cli operations [$default]> " ComplianceAccountProfile
	ComplianceAccountProfile=${ComplianceAccountProfile:-$default}
	default=919568423267
	read -p "Enter Master Account [$default]> " MasterAccount
	MasterAccount=${MasterAccount:-$default}
	default=tah
	read -p "Enter MasterAccount ProfileName for AWS Cli operations [$default]> " MasterAccountProfile
	MasterAccountProfile=${MasterAccountProfile:-$default}
fi
echo -e "ToolsAccount=$ToolsAccount \t ToolsAccountProfile=$ToolsAccountProfile"
echo -e "DevAccount=$DevAccount \t DevAccountProfile=$DevAccountProfile"
echo -e "ComplianceAccount=$ComplianceAccount \t ComplianceAccountProfile=$ComplianceAccountProfile"
echo -e "MasterAccount=$MasterAccount \t MasterAccountProfile=$MasterAccountProfile"

if $batch || ask "Create S3 Bucket and KMS CMS Key and alias in ToolsAccount? " N; then
	aws cloudformation deploy --stack-name aws-org-config-rules-pre-reqs  \
	--template-file ToolsAcct/pre-reqs.yaml \
	--parameter-overrides DevAccount=$DevAccount ComplianceAccount=$ComplianceAccount MasterAccount=$MasterAccount \
	--profile $ToolsAccountProfile
fi

read -p "Enter S3 Bucket created from above > " S3Bucket
read -p "Enter CMK ARN created from above > " CMKArn

if $batch || ask "Create CodeCommit roles for CodePipeline in DevAccount? " N; then
	aws cloudformation deploy --stack-name toolsacct-codepipeline-role \
	--template-file DevAccount/toolsacct-codepipeline-codecommit.yaml \
	--capabilities CAPABILITY_NAMED_IAM \
	--parameter-overrides ToolsAccount=$ToolsAccount CMKARN=$CMKArn \
	--profile $DevAccountProfile
fi

if $batch || ask "Create CloudFormation deployment roles in ComplianceAccount? " N; then
	aws cloudformation deploy --stack-name toolsacct-codepipeline-cloudformation-role \
	--template-file ComplianceAccount/toolsacct-codepipeline-cloudformation-deployer.yaml \
	--capabilities CAPABILITY_NAMED_IAM \
	--parameter-overrides MasterAccount=$MasterAccount ToolsAccount=$ToolsAccount CMKARN=$CMKArn  S3Bucket=$S3Bucket \
	--profile $ComplianceAccountProfile
fi

if $batch || ask "Create CloudFormation deployment roles in MasterAccount? " N; then
	aws cloudformation deploy --stack-name toolsacct-codepipeline-cloudformation-role \
	--template-file MasterAccount/toolsacct-codepipeline-cloudformation-deployer.yaml \
	--capabilities CAPABILITY_NAMED_IAM \
	--parameter-overrides ToolsAccount=$ToolsAccount CMKARN=$CMKArn  S3Bucket=$S3Bucket \
	--profile $MasterAccountProfile
fi

if $batch || ask "Create CodePipeline and build roles in ToolsAccount? " N; then
	aws cloudformation deploy --stack-name aws-org-config-rules-pipeline \
	--template-file ToolsAcct/code-pipeline.yaml \
	--parameter-overrides DevAccount=$DevAccount ComplianceAccount=$ComplianceAccount MasterAccount=$MasterAccount CMKARN=$CMKArn S3Bucket=$S3Bucket --capabilities CAPABILITY_NAMED_IAM \
	--capabilities CAPABILITY_NAMED_IAM \
	--profile $ToolsAccountProfile
fi

if $batch || ask "Deploy Cross Account Roles to ToolsAccount? " N; then
	aws cloudformation deploy --stack-name custom-config-xaccount-roles \
	 --template-file MemberAccount/01-custom-config-xaccount-roles.yaml \
	 --capabilities CAPABILITY_NAMED_IAM \
	 --profile betsy
fi
if $batch || ask "Deploy Cross-account roles to MemberAccount? " N; then
	aws cloudformation deploy --stack-name custom-config-xaccount-roles \
	 --template-file MemberAccount/01-custom-config-xaccount-roles.yaml \
	 --capabilities CAPABILITY_NAMED_IAM \
	 --profile julio
fi
if $batch || ask "Deploy Cross-account roles to DevAccount? " N; then
	aws cloudformation deploy --stack-name custom-config-xaccount-roles \
	 --template-file MemberAccount/01-custom-config-xaccount-roles.yaml \
	 --capabilities CAPABILITY_NAMED_IAM \
	 --profile thunt
fi
# if $batch || ask "Deploy Cross-account roles to ComplianceAccount? " N; then
# 	aws cloudformation deploy --stack-name custom-config-xaccount-roles \
# 	 --template-file MemberAccount/01-custom-config-xaccount-roles.yaml \
# 	 --capabilities CAPABILITY_NAMED_IAM \
# 	 --profile tahunt
# fi

echo -e "\n######### Reconfiguring resources with X-Account roles. ########"

if $batch || ask "Add Permissions to the CMK? " N; then
	aws cloudformation deploy --stack-name aws-org-config-rules-pre-reqs  \
	--template-file ToolsAcct/pre-reqs.yaml \
	--parameter-overrides CodeBuildCondition=true \
	--profile $ToolsAccountProfile
fi

if $batch || ask "Add Permissions to the Cross Accounts ?" N; then
	aws cloudformation deploy --stack-name aws-org-config-rules-pipeline \
	--template-file ToolsAcct/code-pipeline.yaml \
	--parameter-overrides CrossAccountCondition=true \
	--capabilities CAPABILITY_NAMED_IAM \
	--profile $ToolsAccountProfile
fi