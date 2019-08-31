# Setting up a Test Environment

## Prerequisites

You must have an AWS account.
Setting up the test stack will require permissions for IAM, CloudFormation, and CloudWatch Logs.

The instructions below will sometimes use the [AWS CLI](https://aws.amazon.com/cli/).

At Invenia we have a dedicated account for public CI, so the actions below are performed with an administrator role in that account.

## Setting up the Account

These are manual steps to take when setting up the testing account.

### Create a Testing User

This user will be responsible for actually running the tests.
The user will be passed to CloudFormation on stack creation and given permission to assume the stack's testing role.
This approach allows the same user to be used for multiple testing stacks in the same account, which is useful for iterating on stack design.

Since the user is given permissions by CloudFormation, it needs no permissions at creation time.
It will, however, need access keys.
Save these for running tests, ideally as a profile in your [AWS credentials file](https://docs.aws.amazon.com/cli/latest/userguide/cli-config-files.html).

At Invenia, we create a user dedicated to the project, in this case called `CloudWatchLogsJL`.

### Create a Dedicated Stack Creation Role (Optional)

If you wish to have greater control and visibility over stack creation, create a dedicated administrator role which will manage the creation of resources in the test stack.
Edit the Trust Relationship for this role in the IAM console to allow access from CloudFormation.
Adding this to the role's policy statement will accomplish this:

```json
{
  "Effect": "Allow",
  "Principal": {
    "Service": "cloudformation.amazonaws.com"
  },
  "Action": "sts:AssumeRole"
}
```


## Creating the Stack

### Variables

```sh
# relative to the package directory
export TEMPLATE=file://test/aws/cwl_test.yml

# the testing user created above
export PUBLIC_CI_USER=CloudWatchLogsJL

# your stack name
# all the Invenia stack names will be CloudWatchLogs-jl-#####, counting up
# do not attempt to give two stacks the same name
export STACK_NAME=CloudWatchLogs-jl-00011
```

### Command

To create a basic stack with your current profile:

```sh
aws cloudformation create-stack \
    --template-body $TEMPLATE \
    --parameters ParameterKey=PublicCIUser,ParameterValue=$PUBLIC_CI_USER \
    --stack-name $STACK_NAME
```

Or if you created a dedicated stack creation role in the optional step above:

```sh
export STACK_ROLE_ARN=arn:aws:iam::263813748431:role/CloudFormationAdmin

aws cloudformation create-stack \
    --template-body $TEMPLATE \
    --capabilities CAPABILITY_NAMED_IAM \
    --role-arn $STACK_ROLE_ARN \
    --parameters ParameterKey=PublicCIUser,ParameterValue=$PUBLIC_CI_USER \
    --stack-name $STACK_NAME
```

You can check the status of stack creation with the AWS CloudFormation console or with the AWS CLI.

### Running Tests

You must authenticate with the testing user, either by setting [environment variables](https://docs.aws.amazon.com/cli/latest/userguide/cli-environment.html) or using an AWS profile.
The environment variables for Invenia's stack are privately set in the Travis CI repository settings.

The stack used to test is versioned with the tests, in the [`test/online.jl`](https://github.com/invenia/CloudWatchLogs.jl/blob/master/test/online.jl) file.
If you wish to override this for your own testing, set the `CLOUDWATCHLOGSJL_STACK_NAME` environment variable.

After this, running Julia tests normally should work!
