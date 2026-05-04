################################################################################
# Base
################################################################################
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}

# Generate TLS certificate for AWS Load Balancer Controller webhook
resource "tls_private_key" "cloud_usg_com" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "cloud_usg_com" {
  private_key_pem = tls_private_key.cloud_usg_com.private_key_pem

  subject {
    common_name  = "cloud-usg.com"
    organization = "cloud-usg.com"
  }

  dns_names             = ["cloud-usg.com", "*.cloud-usg.com"]
  validity_period_hours = 87600 # 10 years
  is_ca_certificate     = true

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "cert_signing",
  ]
}

# Generate AWS Load Balancer Controller YAML using templatefile
resource "local_file" "aws_load_balancer_controller_yaml" {
  content = templatefile("${path.module}/aws-load-balancer-controller.yaml", {
    cluster_name = local.cluster_name
    role_arn     = module.aws_load_balancer_controller_irsa_role.iam_role_arn
    tls_cert     = base64encode(tls_self_signed_cert.cloud_usg_com.cert_pem)
    tls_key      = base64encode(tls_private_key.cloud_usg_com.private_key_pem)
    vpc_id       = var.vpc_id
    aws_region   = data.aws_region.current.name
  })
  filename = "/tmp/aws-load-balancer-controller-${local.cluster_name}.yaml"
}

# Deploy AWS Load Balancer Controller CRDs first
resource "null_resource" "deploy_aws_load_balancer_controller_crds" {
  depends_on = [
    aws_eks_node_group.core_nodegroup,
    aws_eks_access_entry.admin,
    aws_eks_access_policy_association.admin_policy
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Update kubeconfig
      aws eks update-kubeconfig --region ${data.aws_region.current.name} --name ${local.cluster_name} && \
      
      # Install official AWS Load Balancer Controller CRDs
      kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master" && \
      
      # Wait for CRDs to be established
      kubectl wait --for condition=established --timeout=60s crd/ingressclassparams.elbv2.k8s.aws && \
      kubectl wait --for condition=established --timeout=60s crd/targetgroupbindings.elbv2.k8s.aws
    EOT
  }
}

# Deploy AWS Load Balancer Controller via kubectl
resource "null_resource" "deploy_aws_load_balancer_controller" {
  depends_on = [
    null_resource.deploy_aws_load_balancer_controller_crds,
    module.aws_load_balancer_controller_irsa_role,
    local_file.aws_load_balancer_controller_yaml
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Apply the AWS Load Balancer Controller
      kubectl apply -f ${local_file.aws_load_balancer_controller_yaml.filename} && \
      # Check deployment status instead of waiting
      kubectl get deployment aws-load-balancer-controller -n kube-system && \
      kubectl describe deployment aws-load-balancer-controller -n kube-system
    EOT
  }
}

# Generate Kubernetes manifests using templatefile
resource "local_file" "kubernetes_manifests_yaml" {
  content = templatefile("${path.module}/kubernetes-manifests.yaml", {
    database_url = var.database_url
    litellm_master_key = var.litellm_master_key
    litellm_salt_key = var.litellm_salt_key
    openai_api_key = var.openai_api_key
    azure_openai_api_key = var.azure_openai_api_key
    azure_api_key = var.azure_api_key
    anthropic_api_key = var.anthropic_api_key
    groq_api_key = var.groq_api_key
    cohere_api_key = var.cohere_api_key
    co_api_key = var.co_api_key
    hf_token = var.hf_token
    huggingface_api_key = var.huggingface_api_key
    databricks_api_key = var.databricks_api_key
    gemini_api_key = var.gemini_api_key
    codestral_api_key = var.codestral_api_key
    mistral_api_key = var.mistral_api_key
    azure_ai_api_key = var.azure_ai_api_key
    nvidia_nim_api_key = var.nvidia_nim_api_key
    xai_api_key = var.xai_api_key
    perplexityai_api_key = var.perplexityai_api_key
    github_api_key = var.github_api_key
    deepseek_api_key = var.deepseek_api_key
    ai21_api_key = var.ai21_api_key
    langsmith_api_key = var.langsmith_api_key
    langfuse_secret_key = var.langfuse_secret_key
    desired_capacity = var.desired_capacity
    nodegroup_name = aws_eks_node_group.core_nodegroup.node_group_name
    ecr_litellm_repository_url = var.ecr_litellm_repository_url
    litellm_version = var.litellm_version
    config_bucket_name = var.config_bucket_name
    redis_host = var.redis_host
    redis_port = var.redis_port
    redis_password = var.redis_password
    langsmith_project = var.langsmith_project
    langsmith_default_run_name = var.langsmith_default_run_name
    aws_region = data.aws_region.current.name
    litellm_local_model_cost_map = var.disable_outbound_network_access ? "True" : "False"
    no_docs = var.disable_swagger_page ? "True" : "False"
    disable_admin_ui = var.disable_admin_ui ? "True" : "False"
    langfuse_public_key = var.langfuse_public_key
    langfuse_host = var.langfuse_host
    ecr_middleware_repository_url = var.ecr_middleware_repository_url
    okta_issuer = var.okta_issuer
    okta_audience = var.okta_audience
    alb_scheme = var.public_load_balancer ? "internet-facing" : "internal"
    certificate_arn = var.certificate_arn
    wafv2_acl_arn = var.wafv2_acl_arn
    record_name = var.record_name
    litellm_pod_role_arn = aws_iam_role.litellm_pod_role.arn
    enable_hpa = var.enable_hpa
    hpa_min_replicas = var.hpa_min_replicas
    hpa_max_replicas = var.hpa_max_replicas
    hpa_cpu_target_percentage = var.hpa_cpu_target_percentage
    hpa_memory_target_percentage = var.hpa_memory_target_percentage
    litellm_cpu_request = var.litellm_cpu_request
    litellm_cpu_limit = var.litellm_cpu_limit
    litellm_memory_request = var.litellm_memory_request
    litellm_memory_limit = var.litellm_memory_limit
    middleware_cpu_request = var.middleware_cpu_request
    middleware_cpu_limit = var.middleware_cpu_limit
    middleware_memory_request = var.middleware_memory_request
    middleware_memory_limit = var.middleware_memory_limit
  })
  filename = "/tmp/kubernetes-manifests-${local.cluster_name}.yaml"
}

# Wait for ALB controller to be ready
resource "null_resource" "wait_alb_controller_ready" {
  depends_on = [null_resource.deploy_aws_load_balancer_controller]

  provisioner "local-exec" {
    command = "kubectl wait --for=condition=available --timeout=120s deployment/aws-load-balancer-controller -n kube-system"
  }
}

# Deploy Kubernetes resources via kubectl
resource "null_resource" "deploy_kubernetes_resources" {
  depends_on = [
    null_resource.wait_alb_controller_ready,
    local_file.kubernetes_manifests_yaml,
    aws_eks_node_group.core_nodegroup,
    aws_eks_addon.coredns,
    aws_eks_addon.vpc_cni
  ]

  provisioner "local-exec" {
    command = <<-EOT
      # Apply the manifests
      kubectl apply -f ${local_file.kubernetes_manifests_yaml.filename} && \
      kubectl wait --for=condition=available --timeout=600s deployment/litellm-deployment
    EOT
  }


}





# Generate ingress manifest using templatefile
resource "local_file" "ingress_manifest_yaml" {
  content = templatefile("${path.module}/ingress-manifest.yaml", {
    alb_scheme      = var.public_load_balancer ? "internet-facing" : "internal"
    certificate_arn = var.certificate_arn
    wafv2_acl_arn   = var.wafv2_acl_arn
    record_name     = var.record_name
  })
  filename = "/tmp/ingress-manifest-${local.cluster_name}.yaml"
}

# Deploy and destroy ingress
resource "null_resource" "deploy_ingress" {
  depends_on = [
    null_resource.deploy_kubernetes_resources
  ]

  provisioner "local-exec" {
    command = "kubectl apply -f ${local_file.ingress_manifest_yaml.filename}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete ingress litellm-ingress --ignore-not-found=true && kubectl delete ingressclass alb --ignore-not-found=true && sleep 60"
  }
}

module "aws_load_balancer_controller_irsa_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.52.2"

  role_name                              = "${var.name}-aws-load-balancer-controller"
  attach_load_balancer_controller_policy = true

  oidc_providers = {
    ex = {
      provider_arn               = aws_iam_openid_connect_provider.this.arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }
}

# Get the ALB details using data source - Temporarily commented out
# data "aws_lb" "ingress_alb" {
#   depends_on = [null_resource.deploy_kubernetes_resources]
#   
#   tags = {
#     "elbv2.k8s.aws/cluster" = local.cluster_name
#     "ingress.k8s.aws/stack" = "default/litellm-ingress"
#   }
# }