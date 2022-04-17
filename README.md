# Terraform + AWS CodeBuild

This is demo repository that shows how to setup AWS CodeBuild via Terraform.
It shows as well, based on a sample Node.js app, how to configure a simple pipeline to run automated tests, build a Docker container and publish it to a private AWS ECR repository.

Before starting with Terraform actions, you need a bucket to store tfstate:
```
aws s3api create-bucket --bucket "acme-tfstate-$(uuidgen)" --region eu-west-1 --create-bucket-configuration LocationConstraint=eu-west-1
```

Copy the returned bucket name and replace in the Terraform backend config:
```
backend "s3" {
  bucket = "REPLACEME"
  ...
}
```

Init terraform:
```
terraform init
```

Create a `.tfvars` file with all the variables declared in `variables.tf` (there is a sample file).

Create infrastructure:
```
terraform apply -var-file=.tfvars
```