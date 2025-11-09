terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws" 
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}


#creating vpc 
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames  = true 
  enable_dns_support = true 

  tags = {
    Name = "tarantula_vpc"
  }
}


#internet gateway 
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "tarantula_igw"
  }
}


#public subnet for EC2 (app)
resource "aws_subnet" "public_1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "10.0.1.0/24" 
  availability_zone = "us-east-1a" 
  map_public_ip_on_launch = true


  tags = {
    Name = "tarantula_public_subnet_1"
  }
}

#public subnet for jenkins server 
resource "aws_subnet" "public_2" {
  vpc_id = aws_vpc.main.id 
  cidr_block = "10.0.3.0/24" 
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "tarantula_public_subnet_2"
  }
}

#route table for vpc 
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id 

  route {
    cidr_block = "0.0.0.0/0" 
    gateway_id = aws_internet_gateway.main.id 
  }

  tags = {
    Name = "tarantula_rt"
  }
}






#route table association for public subnet 1 (app server)
resource "aws_route_table_association" "public_1" {
  subnet_id = aws_subnet.public_1.id 
  route_table_id = aws_route_table.main.id 
}


#route table association for public subnet 2 (jenkins server)
resource "aws_route_table_association" "public_2" {
  subnet_id = aws_subnet.public_2.id 
  route_table_id = aws_route_table.main.id 
}




#security group for EC2 (app server)
resource "aws_security_group" "app_sg" {
  name = "tarantula_app_sg" 
  description = "security group for app server"
  vpc_id = aws_vpc.main.id 


  #ssh 
  ingress {
    from_port = 22 
    to_port = 22 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"] 
  }

  #http 
  ingress {
    from_port = 80 
    to_port = 80
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"]
  }


  #App port 
  ingress {
    from_port = 3000 
    to_port = 3000
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"]
  }


  #postgresql (cidr blocks is "10.0.0.0/16 because to communicate within the vpc itself)
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp" 
    cidr_blocks = ["10.0.0.0/16"]
  }


  #allowing all outbound traffic
  egress {
    from_port = 0 
    to_port = 0 
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "tarantula_app_sg"
  }
  
}


#security group for jenkins server
resource "aws_security_group" "jenkins_sg" {
  name = "tarantula_jenkins_sg" 
  description = "security group for jenkins server" 
  vpc_id = aws_vpc.main.id


  #jenkins server port 
  ingress {
    from_port = 8080 
    to_port = 8080
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"]
  }


  #ssh 
  ingress {
    from_port = 22
    to_port = 22 
    protocol = "tcp" 
    cidr_blocks = ["0.0.0.0/0"]
  } 

  #allowing all outbound traffic
  egress {
    from_port = 0 
    to_port = 0 
    protocol = "-1" 
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tarantula_jenkins_sg"

  }
}



# app server ec2 instance  + postgres container
resource "aws_instance" "app" {
  ami = "ami-0ecb62995f68bb549"
  instance_type = "t2.micro" 
  subnet_id =  aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.app_sg.id] 
  key_name = aws_key_pair.main.key_name

  tags = {
    Name = "tarantula_app_server"
  }
}


# jenkins server ec2 instance 
resource "aws_instance" "jenkins" {
  ami = "ami-0ecb62995f68bb549"
  instance_type = "t2.micro" 
  subnet_id = aws_subnet.public_2.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name = aws_key_pair.main.key_name

  tags = {
    Name = "tarantula_jenkins_server"
  }
}



#SSH key pair 
resource "aws_key_pair" "main" {
  key_name = "tarantula_key" 
  public_key = file("~/.ssh/id_rsa.pub") 

  tags = {
    Name = "tarantula_key"
  }
}






#outputs 
output "app_ec2_public_ip" {
  value       = aws_instance.app.public_ip
  description = "app server ec2 Public IP"
}

output "jenkins_ec2_public_dns" {
  value       = aws_instance.jenkins.public_ip
  description = "jenkins EC2 Public ip"
}





