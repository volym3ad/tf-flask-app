locals {
  ami = var.ami != "" ? var.ami : data.aws_ami.ubuntu.image_id
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "3.16.0"

  name        = "flask_app"
  description = "Security group for flask_app"
  vpc_id      = module.vpc.vpc_id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "ssh-tcp"]
  egress_rules        = ["all-all"]
}

module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "2.4.0"

  name = "flask-app"

  subnets         = module.vpc.public_subnets
  security_groups = [module.security_group.this_security_group_id]
  internal        = false

  idle_timeout                = 65
  connection_draining         = true
  connection_draining_timeout = 15

  listener = [
    {
      instance_port     = "80"
      instance_protocol = "http"
      lb_port           = "80"
      lb_protocol       = "http"
    },
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  number_of_instances = 1

  instances = [aws_instance.ec2.id]
  tags = merge(
    {
      "Terraform" = "true"
    },
    var.tags,
  )
}

resource "aws_key_pair" "ec2_keypair" {
  key_name   = "flask_app_key"
  public_key = file("keys/id_rsa.pub")
}

locals {
  user_data = <<EOF
#!/bin/bash
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

sudo curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
EOF
}

resource "aws_instance" "ec2" {
  ami                         = local.ami
  instance_type               = var.instance_type
  key_name                    = "flask_app_key"
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = [module.security_group.this_security_group_id]
  associate_public_ip_address = true
  user_data_base64            = base64encode(local.user_data)
  tags = merge(
    {
      "Name"      = "flask_app"
      "Terraform" = "true"
    },
    var.tags
  )
}

data "local_file" "app" {
  filename = "docker/flask_app/app.py"
}

resource "null_resource" "deploy" {
  triggers = {
    app = data.local_file.app.content
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    host        = aws_instance.ec2.public_ip
    private_key = file("keys/id_rsa")
  }
  provisioner "file" {
    source      = "docker/"
    destination = "/home/ubuntu/"
  }
  provisioner "remote-exec" {
    inline = [
      "sleep 120",
      "cd /home/ubuntu",
      "sudo docker-compose down",
      "sudo docker-compose up --build -d"
    ]
  }
  depends_on = [aws_instance.ec2]
}