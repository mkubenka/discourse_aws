# Terraform config example that puts all ./tfmodules together.
#

variable "developer_emails" {
  description = "List of comma delimited emails that will be made admin and developer on initial signup example"
}

variable "credstash_reader_policy_arn" {
  description = "https://github.com/fugue/credstash#secret-reader"
}

variable "smtp_address" {}

variable "smtp_user_name" {}

variable "name_prefix" {
  default = "discourse_dev"
}

variable "cname_prefix" {
  default = "discourse-dev"
}

variable "env_name" {
  default = "discourse-dev"
  description = "Elastic Beanstalk environment name. Must be one of $dev_env_name or $prod_env_name defined in common-variables.sh."
}

variable "discourse_hostname" {
  default = "sandbox.discourse.example.com"
}

variable "ses_active_receipt_rule_set_name" {
  default = "default-rule-set"
}

variable "ses_receipt_rule_set_offset" {
  default = "0"
}

module "common" {
  source = "../discourse_aws/tfmodules/discourse-common/"
}

module "vpc" {
  source = "../discourse_aws/tfmodules/discourse-vpc/"

  name_prefix = "${var.name_prefix}"
}

module "db" {
  source = "../discourse_aws/tfmodules/discourse-db/"

  name_prefix = "${var.name_prefix}"
  subnet_ids = "${module.vpc.private_subnets}"
  vpc_security_group_ids = "${module.vpc.db_security_group_id}"
}

module "eb" {
  source = "../discourse_aws/tfmodules/discourse-eb/"

  name_prefix = "${var.name_prefix}"
  app_name = "${module.common.app_name}"
  env_name = "${var.env_name}"
  cname_prefix = "${var.cname_prefix}"
  vpc_id = "${module.vpc.vpc_id}"
  subnet_id = "${module.vpc.public_subnet}"
  hostname = "${var.discourse_hostname}"
  deployment_policy = "AllAtOnce"
  cert_email = "admin@${var.discourse_hostname}"
  cert_s3_bucket = "${module.common.s3_bucket_certs}"
  certbot_extra_args = "--staging"
  developer_emails = "${var.developer_emails}"
  iam_role_policy_arns = ["${var.credstash_reader_policy_arn}"]
  iam_role_policy_arn_count = "1"
  security_group_ids = ["${module.vpc.web_security_group_id}"]
  db_host = "${module.db.db_host}"
  smtp_address = "${var.smtp_address}"
  smtp_user_name = "${var.smtp_user_name}"
}

module "ses" {
  source = "../discourse_aws/tfmodules/discourse-mail-receiver/"

  name_prefix = "${var.name_prefix}"
  cname_prefix = "${var.cname_prefix}"
  discourse_hostname = "${var.discourse_hostname}"
  discourse_mail_endpoint = "https://${var.discourse_hostname}/admin/email/handle_mail"
  ses_rule_set_name = "${var.ses_active_receipt_rule_set_name}"
  ses_rule_start_position = "${var.ses_receipt_rule_set_offset}"
}
