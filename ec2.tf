resource "aws_instance" "example" {
  ami           = "ami-006f82a1d5a27da54"
  instance_type = "t3.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.mysubnet.id
  security_groups = [aws_default_security_group.default.id]
 
 
  user_data = <<-EOF
  #!/bin/bash
  set -eux

  apt-get update
  apt-get install -y nginx curl

  mkdir -p /var/www/html

  curl -fSL \
    "https://${aws_s3_bucket.portfolio.bucket}.s3.ap-south-1.amazonaws.com/index.html" \
    -o /var/www/html/index.html

  chown www-data:www-data /var/www/html/index.html
  chmod 644 /var/www/html/index.html

  systemctl enable nginx
  systemctl restart nginx
  EOF

  depends_on = [
    aws_s3_object.index,
    aws_s3_object.image
  ]

  tags = {
    Name = "Portfolio-EC2-Nginx"
  }
}
