output "bucket_name" {
  value = aws_s3_bucket.state.bucket
}

output "table_name" {
  value = aws_dynamodb_table.lock.name
}
