output "app_name" {
  value = "${aws_elastic_beanstalk_application.main.name}"
}

output "s3_bucket_sourcebundles" {
  value = "${aws_s3_bucket.sourcebundles.id}"
}

output "s3_bucket_certs" {
  value = "${aws_s3_bucket.certs.id}"
}
