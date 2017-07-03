output "files_s3_bucket" {
  value = "${aws_s3_bucket.files.id}"
}

output "cname" {
  value = "${aws_elastic_beanstalk_environment.main.cname}"
}
