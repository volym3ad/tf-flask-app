# tf-flask-app

Test Flask app to run in AWS. App is deployed via docker-compose.

For test purposes ec2 instance is bootstrapped in public subnet.

DO NOT USE IN PRODUCTION!

## Pre-create (manually)
- S3 bucket
- DynamoDB table
- IAM credentials
- public key added: `keys/id_rsa.pub`

## How to run

- Set AWS credentials
- `terraform init`
- `terraform plan`
- `terraform apply`

## How to update code

- Update app.py file
- `terraform apply`

## How to destroy

- `terraform destroy`