resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

resource "aws_cloudfront_origin_access_identity" "this" {
  comment = "SaaS frontend access"
}

data "aws_iam_policy_document" "allow_cloudfront" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "allow_cloudfront" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.allow_cloudfront.json
}

resource "aws_cloudfront_function" "spa_rewrite" {
  name    = "${var.bucket_name}-spa-rewrite"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = file("${path.module}/spa-redirect.js")
}

resource "aws_cloudfront_distribution" "this" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.this.bucket_regional_domain_name
    origin_id   = "s3-frontend"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    target_origin_id       = "s3-frontend"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_rewrite.arn
    }

    forwarded_values {
      query_string = false
      cookies { forward = "none" }
    }
  }

  dynamic "custom_error_response" {
    for_each = {
      403 = { response_code = 404, response_page_path = "/404.html" }
      404 = { response_code = 404, response_page_path = "/404.html" }
      500 = { response_code = 500, response_page_path = "/50x.html" }
      502 = { response_code = 500, response_page_path = "/50x.html" }
      503 = { response_code = 500, response_page_path = "/50x.html" }
      504 = { response_code = 500, response_page_path = "/50x.html" }
    }
    content {
      error_code         = custom_error_response.key
      response_code      = custom_error_response.value.response_code
      response_page_path = custom_error_response.value.response_page_path
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
