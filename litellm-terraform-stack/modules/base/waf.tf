###############################################################################
# WAFv2 Web ACL
###############################################################################

locals {
  waf_allowed_cidrs = [for cidr in split(",", var.waf_allowed_networks) : trimspace(cidr) if trimspace(cidr) != ""]
}

resource "aws_wafv2_ip_set" "allowed_networks" {
  name               = "LiteLLMAllowedNetworks"
  description        = "Allowed IP ranges for LiteLLM WAF"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = local.waf_allowed_cidrs
}

resource "aws_wafv2_web_acl" "litellm_waf" {
  name        = "LiteLLMWAF"
  description = "WAF for LiteLLM"
  scope       = "REGIONAL"

  default_action {
    block {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "LiteLLMWebAcl"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AllowedNetworks"
    priority = 0

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.allowed_networks.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "LiteLLMAllowedNetworks"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet-Exclusions"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"

        rule_action_override {
          name = "NoUserAgent_HEADER"
          action_to_use {
            count {}
          }
        }

        rule_action_override {
          name = "SizeRestrictions_BODY"
          action_to_use {
            count {}
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "LiteLLMCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "LiteLLMKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

}
