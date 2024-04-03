provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "demo-server" {
  ami           = "ami-053b0d53c279acc90"
  instance_type = "t3.medium"
  key_name      = "react-lab"
  vpc_security_group_ids = [aws_security_group.demo-sg.id]
  subnet_id              = aws_subnet.react-lab-public-subnet-01.id
  for_each               = toset(["react-jenkins-master", "react-build-slave", "react-ansible"])
  tags = {
    Name = "${each.key}"
  }
}

resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "SSH Access"
  vpc_id      = aws_vpc.react-lab-vpc.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins port"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh-port"

  }
}

resource "aws_vpc" "react-lab-vpc" {
  cidr_block = "10.1.0.0/16"
  tags = {
    Name = "react-lab-vpc"
  }

}

resource "aws_subnet" "react-lab-public-subnet-01" {
  vpc_id                  = aws_vpc.react-lab-vpc.id
  cidr_block              = "10.1.1.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"
  tags = {
    Name = "react-lab-public-subent-01"
  }
}

resource "aws_subnet" "react-lab-public-subnet-02" {
  vpc_id                  = aws_vpc.react-lab-vpc.id
  cidr_block              = "10.1.2.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1b"
  tags = {
    Name = "react-lab-public-subent-02"
  }
}

resource "aws_internet_gateway" "react-lab-igw" {
  vpc_id = aws_vpc.react-lab-vpc.id
  tags = {
    Name = "react-lab-igw"
  }
}

resource "aws_route_table" "react-lab-public-rt" {
  vpc_id = aws_vpc.react-lab-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.react-lab-igw.id
  }
}

resource "aws_route_table_association" "react-lab-rta-public-subnet-01" {
  subnet_id      = aws_subnet.react-lab-public-subnet-01.id
  route_table_id = aws_route_table.react-lab-public-rt.id
}

resource "aws_route_table_association" "react-lab-rta-public-subnet-02" {
  subnet_id      = aws_subnet.react-lab-public-subnet-02.id
  route_table_id = aws_route_table.react-lab-public-rt.id
}


//  Comment out below modules to remove Kubernetes cluster
//  This command needs to be run on Jenkins build server after K8 cluster is deployed
//  aws eks update-kubeconfig --region us-east-1 --name devops-workshop-eks-01
// module "sgs" {
//    source = "../sg_eks"
//    vpc_id     =     aws_vpc.react-lab-vpc.id
// }

//  module "eks" {
//       source = "../eks"
//       vpc_id     =     aws_vpc.react-lab-vpc.id
//      subnet_ids = [aws_subnet.react-lab-public-subnet-01.id,aws_subnet.react-lab-public-subnet-02.id]
//       sg_ids = module.sgs.security_group_public
// }
