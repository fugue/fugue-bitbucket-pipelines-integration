# EC2 INSTANCE(S)

resource "aws_instance" "app_server18391111" {
  ami           = "ami-074cce78125f09d61"
  instance_type = "t2.micro"

  
  # Un-comment below to satisfy FG_R00253
  iam_instance_profile = aws_iam_instance_profile.test_profile.name
  
  # Comment below to satisfy FG_R00271
  #associate_public_ip_address = true

  tags = {
    Name = "ExampleAppServerInstance18391111"
    Team = "dev"
  }
}

# IAM INSTANCE PROFILE(S)

resource "aws_iam_instance_profile" "test_profile" {
  name = "test_profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "test_role"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}