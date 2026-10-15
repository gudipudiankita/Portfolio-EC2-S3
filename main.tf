# main.tf

# 1. Create the S3 bucket for the portfolio website
resource "aws_s3_bucket" "portfolio" {
  bucket = "portn746ndjh58557"

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

# 4. Allow public read access to website objects
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

# 5. Construct the public profile image URL
locals {
 portfolio_image_url = "https://${aws_s3_bucket.portfolio.bucket}.s3.ap-south-1.amazonaws.com/ankita.png"

  # Read the HTML prepared by the GitHub Actions workflow.
  # Replace the local image filename with the S3 image URL.
  updated_html = replace(
    file("${path.module}/site/index.html"),
    "ankita.png",
    local.portfolio_image_url
  )

  # Upload all remaining website assets, excluding the separately
  # managed index.html and ankita.png.
  website_assets = toset([
    for file_name in fileset("${path.module}/site", "**") :
    file_name
    if file_name != "index.html" && file_name != "ankita.png"
  ])

  content_types = {
    html = "text/html"
    css  = "text/css"
    js   = "application/javascript"
    png  = "image/png"
    jpg  = "image/jpeg"
    jpeg = "image/jpeg"
    svg  = "image/svg+xml"
    ico  = "image/x-icon"
    json = "application/json"
    pdf  = "application/pdf"
    webp = "image/webp"
    txt  = "text/plain"
    woff = "font/woff"
    woff2 = "font/woff2"
  }
}

# 6. Upload profile image to S3
resource "aws_s3_object" "image" {
  bucket = aws_s3_bucket.portfolio.id
  key    = "ankita.png"

  source = "${path.module}/site/ankita.png"
  etag   = filemd5("${path.module}/site/ankita.png")

  content_type = "image/png"

  depends_on = [
    aws_s3_bucket_policy.portfolio
  ]
}

# 7. Upload the updated HTML to S3
resource "aws_s3_object" "index" {
  bucket = aws_s3_bucket.portfolio.id
  key    = "index.html"

  content      = local.updated_html
  content_type = "text/html"

  depends_on = [
    aws_s3_object.image
  ]
}

# 8. Upload other website assets (CSS, JavaScript, and so on)
resource "aws_s3_object" "assets" {
  for_each = local.website_assets

  bucket = aws_s3_bucket.portfolio.id
  key    = each.value

  source = "${path.module}/site/${each.value}"
  etag   = filemd5("${path.module}/site/${each.value}")

  content_type = lookup(
    local.content_types,
    lower(element(reverse(split(".", each.value)), 0)),
    "application/octet-stream"
  )

  depends_on = [
    aws_s3_bucket_policy.portfolio
  ]
}

# 9. Outputs
output "portfolio_bucket_arn" {
  description = "ARN of the S3 portfolio bucket"
  value       = aws_s3_bucket.portfolio.arn
}

output "portfolio_image_url" {
  description = "Public S3 URL of the profile image"
  value       = local.portfolio_image_url
}

output "portfolio_s3_website_url" {
  description = "S3 static website endpoint"
  value       = "http://${aws_s3_bucket_website_configuration.portfolio.website_endpoint}"
}
