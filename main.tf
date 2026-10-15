# 1. Create the S3 bucket for the portfolio website
resource "aws_s3_bucket" "portfolio" {
  bucket = "portn7494557"

  tags = {
    Name        = "AnkitaPortfolio"
    Environment = "Production"
  }
}

# 2. Configure public access settings
resource "aws_s3_bucket_public_access_block" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  block_public_acls       = false
  ignore_public_acls      = false
  block_public_policy     = false
  restrict_public_buckets = false
}

# 3. Enable static website hosting
resource "aws_s3_bucket_website_configuration" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

# 4. Allow public access to website objects
resource "aws_s3_bucket_policy" "portfolio" {
  bucket = aws_s3_bucket.portfolio.id

  depends_on = [
    aws_s3_bucket_public_access_block.portfolio
  ]

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.portfolio.arn}/*"
      }
    ]
  })
}

# Upload the image from the checked-out portfolio repository
resource "aws_s3_object" "image" {
  bucket = aws_s3_bucket.portfolio.id
  key    = "ankita.png"

  source = "${path.module}/portfolio/ankita.png"
  etag   = filemd5("${path.module}/portfolio/ankita.png")

  content_type = "image/png"

  depends_on = [
    aws_s3_bucket_policy.portfolio
  ]
}

# Generate the S3 image URL and update the HTML
locals {
  portfolio_image_url = "https://${aws_s3_bucket.portfolio.bucket}.s3.ap-south-1.amazonaws.com/ankita.png"

  updated_html = replace(
    file("${path.module}/portfolio/index.html"),
    "ankita.png",
    local.portfolio_image_url
  )
}

# 7. Upload the updated HTML file
resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.portfolio.id
  key    = "index.html"

  content      = local.updated_html
  content_type = "text/html"

  depends_on = [
    aws_s3_object.image
  ]
}

# 8. Output the bucket ARN
output "portfolio_bucket_arn" {
  description = "ARN of the portfolio S3 bucket"
  value       = aws_s3_bucket.portfolio.arn
}

# 9. Output the profile image URL
output "portfolio_image_url" {
  description = "Public URL of the profile image"
  value       = local.portfolio_image_url
}

# 10. Output the static website URL
output "portfolio_s3_website_url" {
  description = "S3 static website endpoint"
  value       = "http://${aws_s3_bucket_website_configuration.portfolio.website_endpoint}"
}
