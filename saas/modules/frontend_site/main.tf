resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_policy" "public" {
  bucket = aws_s3_bucket.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = ["s3:GetObject"]
      Resource  = "${aws_s3_bucket.this.arn}/*"
    }]
  })
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = "s3-frontend"
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  price_class = "PriceClass_100"
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.this.domain_name
}
