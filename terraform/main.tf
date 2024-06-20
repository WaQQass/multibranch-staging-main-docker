provider "aws" {
  region = "us-west-1"  # Replace with your desired AWS region
}

# Define the IAM role for SSM managed instance core access
resource "aws_iam_role" "ssm_role" {
  name               = "SSMInstanceRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# Attach AmazonSSMManagedInstanceCore policy to the IAM role
resource "aws_iam_policy_attachment" "ssm_role_attachment" {
  name       = "SSMInstanceRoleAttachment"
  roles      = [aws_iam_role.ssm_role.name]
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Define the EC2 instance
resource "aws_instance" "web" {
  ami           = "ami-08012c0a9ee8e21c4"  # Replace with the AMI ID for your region
  instance_type = "t2.micro"
  key_name      = "california"

  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2_profile.name  # Attach IAM role to instance

  tags = {
    Name = "by_jenkins_docker"
  }
}

# Define IAM instance profile and attach to the EC2 instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "SSMInstanceProfile"
  role = aws_iam_role.ssm_role.name
}

# Define the security group
resource "aws_security_group" "allow_ssh_http" {
  name        = "allow_ssh_http"
  description = "Allow SSH and HTTP traffic"

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
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_http"
  }
}
