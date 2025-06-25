resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
}

data "aws_iam_policy_document" "require_costcenter" {
  statement {
    sid    = "DenyMissingCostCenterTag"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]

    condition {
      test     = "Null"
      variable = "s3:RequestObjectTag/CostCenter"
      values   = ["true"]
    }
  }

  dynamic "statement" {
    for_each = toset(var.tenant_ids)
    content {
      sid    = "EnforceCostCenter-${statement.value}"
      effect = "Deny"

      principals {
        type        = "*"
        identifiers = ["*"]
      }

      actions   = ["s3:PutObject"]
      resources = ["${aws_s3_bucket.this.arn}/${statement.value}/*"]

      condition {
        test     = "StringNotEquals"
        variable = "s3:RequestObjectTag/CostCenter"
        values   = [statement.value]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "require_costcenter" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.require_costcenter.json
}

resource "aws_s3_object" "folders" {
  for_each = toset(var.tenant_ids)
  bucket   = aws_s3_bucket.this.id
  key      = "${each.value}/"
  content  = ""
  tags = {
    CostCenter = each.value
  }
}

output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}
