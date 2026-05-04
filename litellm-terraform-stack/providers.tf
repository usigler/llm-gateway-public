terraform {
  backend "s3" {}
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  SolutionNameKeySatisfyingRestrictions = "Guidance-for-Running-Generative-AI-Gateway-Proxy-on-AWS"
  common_labels = {
    project     = "llmgateway"
    AWSSolution = "ToDo"
    GithubRepo  = "https://github.com/aws-solutions-library-samples/"
    SolutionID  = "SO9022"
    SolutionNameKey = "Guidance for Running Generative AI Gateway Proxy on AWS"
    SolutionVersionKey = "1.0.0"
  }
}


provider "aws" {
  default_tags {
    tags = local.common_labels
  }
}


# Kubernetes and Helm providers removed - using null_resource + local-exec instead

provider "tls" {}
