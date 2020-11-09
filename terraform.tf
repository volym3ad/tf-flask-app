terraform {
  required_version = ">= 0.12.0"

  backend "s3" {
    bucket         = "tf-flask-app-state"
    region         = "us-east-1"
    key            = "state/flask-app.tfstate"
    dynamodb_table = "flask-app-terraformStateLock"
  }
}

provider "aws" {
  version = "3.14.1"
  region  = var.region
}
