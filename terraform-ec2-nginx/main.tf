provider "aws" {
  region = "ap-south-1"
}

provider "aws" {
  alias  = "us"
  region = "us-east-1"
}

# ----------- SECURITY GROUP -------------
resource "aws_security_group" "nginx_sg" {
  name        = "nginx-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "nginx_sg_us" {
  provider = aws.us
  name     = "nginx-sg-us"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "user_data" {
  template = <<EOF
#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
sudo systemctl start nginx
sudo systemctl enable nginx
echo "<h1>Terraform Nginx Success - $(hostname)</h1>" > /var/www/html/index.html
EOF
}

# ----------- INSTANCE 1 (India) ----------
resource "aws_instance" "ec2_india" {
  ami           = "ami-0f5ee92e2d63afc18" # Ubuntu (ap-south-1)
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.nginx_sg.id]

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "Terraform-India"
  }
}

# ----------- INSTANCE 2 (US) ----------
resource "aws_instance" "ec2_us" {
  provider      = aws.us
  ami           = "ami-053b0d53c279acc90" # Ubuntu (us-east-1)
  instance_type = var.instance_type
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.nginx_sg_us.id]

  user_data = data.template_file.user_data.rendered

  tags = {
    Name = "Terraform-US"
  }
}

output "india_ip" {
  value = aws_instance.ec2_india.public_ip
}

output "us_ip" {
  value = aws_instance.ec2_us.public_ip
}
