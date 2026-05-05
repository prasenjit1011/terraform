provider "aws" {
  region = var.aws_region
}

# -----------------------------
# S3 Bucket
# -----------------------------
resource "aws_s3_bucket" "website" {
  bucket = var.bucket_name
}

# -----------------------------
# Website Hosting
# -----------------------------
resource "aws_s3_bucket_website_configuration" "website" {
  bucket = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}

# -----------------------------
# Public Access Block (ALLOW PUBLIC)
# -----------------------------
resource "aws_s3_bucket_public_access_block" "public" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# -----------------------------
# Bucket Policy (Public Read)
# -----------------------------
resource "aws_s3_bucket_policy" "public_read" {
  bucket = aws_s3_bucket.website.id

  depends_on = [aws_s3_bucket_public_access_block.public]

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.website.arn}/*"
      }
    ]
  })
}

# -----------------------------
# Content Types
# -----------------------------
locals {
  content_types = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
  }

  site_files = fileset("${path.module}/website", "**")
}

# -----------------------------
# Upload Files (FIXED)
# -----------------------------
resource "aws_s3_object" "files" {
  for_each = { for file in local.site_files : file => file }

  bucket = aws_s3_bucket.website.id
  key    = each.value
  source = "${path.module}/website/${each.value}"

  etag = filemd5("${path.module}/website/${each.value}")

  content_type = lookup(
    local.content_types,
    lower(split(".", each.value)[length(split(".", each.value)) - 1]),
    "application/octet-stream"
  )
}