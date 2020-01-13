# Reference Architecture: Cross Account AWS CodePipeline

This reference architecture demonstrates how to push code hosted in [AWS CodeCommit](code-commit-url) repository in Development Account,
use [AWS CodeBuild](code-build-url) to do application build, store the output artifacts in S3Bucket and deploy these artifacts to Test
and Production Accounts using [AWS CloudFormation](clouformation-url). This orchestration of code movement from code checkin to deployment
is securely handled by [AWS CodePipeline](code-pipeline-url).


[![](images/architecture.png)][architecture]

## Running the example

#### 1. Clone the sample Lambda function GitHub repository

[Clone](https://help.github.com/articles/cloning-a-repository/) the [AWS LAMBDA sample application](https://github.com/awslabs/aws-pipeline-to-service-catalog.git) GitHub repository.

From your terminal application, execute the following command:

```console
git clone https://github.com/awslabs/aws-pipeline-to-service-catalog.git
```

This creates a directory named `aws-pipeline-to-service-catalog` in your current directory, which contains the code for the AWS Lambda function sample application.

#### 2. Create [AWS CodeCommit](code-commit-url) repository in Development Account

Follow the [instructions here](http://docs.aws.amazon.com/codecommit/latest/userguide/getting-started.html#getting-started-create-repo) to create a CodeCommit repository
in the Development Account.Name your repository as sample-lambda

Alternatively, from your terminal application, execute the following command. You may refer [here](http://docs.aws.amazon.com/codecommit/latest/userguide/how-to-create-repository.html#how-to-create-repository-cli)
on further details, in order to setup AWS Cli , if required.

```console
aws codecommit create-repository --repository-name sample-lambda --repository-description "Sample Lambda Function"
```

Note the cloneUrlHttp URL in the response from above CLI.

#### 3. Add a new remote

From your terminal application, execute the following command:

```console
git remote add AWSCodeCommit HTTP_CLONE_URL_FROM_STEP_2
```

Follow the instructions [here](http://docs.aws.amazon.com/codecommit/latest/userguide/setting-up.html) for local git setup required to push code to CodeCommit repository.

#### 4. Push the code AWS CodeCommit

From your terminal application, execute the following command:

```console
git push AWSCodeCommit master
```

[code-commit-url]: https://aws.amazon.com/devops/continuous-delivery/
[code-build-url]: https://aws.amazon.com/codebuild/
[code-pipeline-url]: https://aws.amazon.com/codepipeline/
[clouformation-url]: https://aws.amazon.com/cloudformation/
[lambda-url]: https://aws.amazon.com/lambda/


h2. Useful Commands


ENTER_DEV_ACCT=123133550781 #thunt
ENTER_COMPLY_ACCT=567207295412 #tahunt
ENTER_PROD_ACCT=930856341568 #julio
ENTER_TOOLS_ACCT=782391863272 #betsy
MASTER_ACCT=919568423267 #tah
CMKARN=arn:aws:kms:us-east-2:782391863272:key/5ed746d1-acb6-4863-9fec-f890f967409e
S3BUX=aws-org-config-rules-pre-reqs-artifactbucket-i6w3irq68q0i

aws codecommit create-repository --repository-name aws-org-config-rules --repository-description "Organization Config Rules both Managed and Custom." --profile thunt

git remote add AWSCodeCommit https://git-codecommit.us-east-2.amazonaws.com/v1/repos/aws-org-config-rules

git push AWSCodeCommit master


1. In the Tools account, create S3, KMS, Alias, grant access to Dev, Test, Prod accts.
aws cloudformation deploy --stack-name aws-org-config-rules-pre-reqs \
--template-file ToolsAcct/pre-reqs.yaml --parameter-overrides \
DevAccount=$ENTER_DEV_ACCT ComplianceAccount=$ENTER_COMPLY_ACCT \
ProductionAccount=$MASTER_ACCT --profile betsy
2. In the Dev account, create the roles to be assumed by CodePipeline in Tools acct.
aws cloudformation deploy --stack-name toolsacct-codepipeline-role \
--template-file DevAccount/toolsacct-codepipeline-codecommit.yaml \
--capabilities CAPABILITY_NAMED_IAM \
--parameter-overrides ToolsAccount=$ENTER_TOOLS_ACCT CMKARN=$CMKARN \
--profile thunt
3. In the Test and Prod accounts, create IAM roles to be assumed by the pipeline that create, deploy, and update the Lambda function through CloudFormation.
aws cloudformation deploy --stack-name toolsacct-codepipeline-cloudformation-role \
--template-file ComplianceAccount/toolsacct-codepipeline-cloudformation-deployer.yaml \
--capabilities CAPABILITY_NAMED_IAM \
--parameter-overrides MasterAccount=$MASTER_ACCT ToolsAccount=$ENTER_TOOLS_ACCT CMKARN=$CMKARN  \
S3Bucket=$S3BUX \
--profile tahunt

aws cloudformation deploy --stack-name toolsacct-codepipeline-cloudformation-role \
--template-file MasterAccount/toolsacct-codepipeline-cloudformation-deployer.yaml \
--capabilities CAPABILITY_NAMED_IAM \
--parameter-overrides ToolsAccount=$ENTER_TOOLS_ACCT \
CMKARN=$CMKARN S3Bucket=$S3BUX \
--profile tah

4.In the Tools account, create AWS CodePipeline with no permissions for the cross accounts (Dev, Test, and Prod).
aws cloudformation deploy --stack-name aws-org-config-rules-pipeline \
--template-file ToolsAcct/code-pipeline.yaml \
--parameter-overrides DevAccount=$ENTER_DEV_ACCT ComplianceAccount=$ENTER_COMPLY_ACCT \
ProductionAccount=$MASTER_ACCT CMKARN=$CMKARN \
S3Bucket=$S3BUX --capabilities CAPABILITY_NAMED_IAM \
--profile betsy

5. In the Tools account, give access to the role created in step 4 to be assumed by AWS CodeBuild to decrypt artifacts in the S3 bucket. This is the same template that was used in step 1, but with different parameters.
aws cloudformation deploy --stack-name aws-org-config-rules-pre-reqs \
--template-file ToolsAcct/pre-reqs.yaml \
--parameter-overrides CodeBuildCondition=true \
--profile betsy

6. In the Tools account, execute this CloudFormation template, which will do the following:
A) Add the IAM role created in step 2. This role is used by AWS CodePipeline in the Tools account for checking out code from the AWS CodeCommit repository in the Dev account.
B) Add the IAM role created in step 3. This role is used by AWS CodePipeline in the Tools account for deploying the code package to the Test and Prod accounts.
aws cloudformation deploy --stack-name aws-org-config-rules-pipeline \
--template-file ToolsAcct/code-pipeline.yaml \
--parameter-overrides CrossAccountCondition=true \
--capabilities CAPABILITY_NAMED_IAM \
--profile betsy


############################ DELETION ############################
aws cloudformation delete-stack --stack-name aws-org-config-rules-pipeline \
--profile betsy

aws cloudformation delete-stack --stack-name omcr-lambda-test \
--profile tahunt

aws cloudformation delete-stack --stack-name toolsacct-codepipeline-cloudformation-role \
--profile tahunt

aws cloudformation delete-stack --stack-name org-managed-config-rules \
--profile tah

aws cloudformation delete-stack --stack-name toolsacct-codepipeline-cloudformation-role \
--profile tah

aws cloudformation delete-stack --stack-name toolsacct-codepipeline-role \
--profile thunt

aws cloudformation delete-stack --stack-name aws-org-config-rules-pre-reqs \
--profile betsy

############################ DESCRIBE ############################
aws cloudformation describe-stacks --stack-name aws-org-config-rules-pipeline \
--profile betsy

aws cloudformation describe-stacks --stack-name toolsacct-codepipeline-cloudformation-role \
--profile tahunt

aws cloudformation describe-stacks --stack-name toolsacct-codepipeline-cloudformation-role \
--profile tah

aws cloudformation describe-stacks --stack-name toolsacct-codepipeline-role \
--profile thunt

aws cloudformation describe-stacks --stack-name aws-org-config-rules-pre-reqs \
--profile betsy

############################ LIST ############################

aws cloudformation list-stacks --profile tahunt

aws cloudformation list-stacks --profile tah

aws cloudformation list-stacks --profile thunt

aws cloudformation list-stacks --profile betsy

####################### TRANSACTION STATUS ####################
aws configservice describe-organization-config-rules --profile tah

aws configservice get-organization-config-rule-detailed-status --organization-config-rule-name ec2-required-tags --profile tah

aws configservice get-organization-config-rule-detailed-status --organization-config-rule-name encrypted-volumes --profile tah

aws configservice delete-organization-config-rule --organization-config-rule-name pge-s3-tags --profile tah


```

