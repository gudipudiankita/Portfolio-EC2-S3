
# 1. Create S3 bucket
resource "aws_s3_bucket" "portfolio" {
  bucket = "portn7494557"
}

# 2. Enable public website access
resource "aws_s3_bucket_public_access_block" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# 3. Display S3 bucket ARN
output "portfolio_bucket_arn" {
  value = aws_s3_bucket.portfolio.arn
}

# 4. Enable static website hosting
resource "aws_s3_bucket_website_configuration" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# 5. Allow public access to website files
resource "aws_s3_bucket_policy" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  depends_on = [
    aws_s3_bucket_public_access_block.portfolio
  ]

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.portfolio.arn}/*"
    }]
  })
}

# 5. Upload profile image
resource "aws_s3_object" "image" {
  bucket       = aws_s3_bucket.portfolio.id
  key          = "ankita.png"
  source       = "${path.module}/ankita.png"
  etag         = filemd5("${path.module}/ankita.png")
  content_type = "image/png"

  depends_on = [
    aws_s3_bucket_policy.portfolio
  ]
}

# 6. Generate S3 image URL and update HTML
locals {
  portfolio_image_url = "https://${aws_s3_bucket.portfolio.bucket}.s3.ap-south-1.amazonaws.com/ankita.png"

  updated_html = replace(
    file("${path.module}/index.html"),
    "ankita.png",
    local.portfolio_image_url
  )
}

# 7. Upload updated HTML to S3
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.portfolio.id
  key          = "index.html"
  content      = local.updated_html
  content_type = "text/html"

  depends_on = [
    aws_s3_object.image
  ]
}

# 8. Outputs
output "portfolio_bucket_arn" {
  value = aws_s3_bucket.portfolio.arn
}

output "portfolio_image_url" {
  value = local.portfolio_image_url
}

output "portfolio_s3_website_url" {
  value = "http://${aws_s3_bucket_website_configuration.portfolio.website_endpoint}"
}



# 10. Display image URL
output "portfolio_image_url" {
  value = local.portfolio_image_url
}

