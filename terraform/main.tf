# Create a VPC
resource "aws_vpc" "myvpc" {
  cidr_block = var.cidr
}
resource "aws_subnet" "sub1" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        =  cidrsubnet(aws_vpc.myvpc.cidr_block,4,1)     
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true
}
resource "aws_subnet" "sub2" {
  vpc_id            = aws_vpc.myvpc.id
  cidr_block        =  cidrsubnet(aws_vpc.myvpc.cidr_block,4,2)     
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch = true
}
resource "aws_internet_gateway" "myIG" {
  vpc_id = aws_vpc.myvpc.id
}
resource "aws_route_table" "myrt" {
  vpc_id = aws_vpc.myvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myIG.id
  }
}
resource "aws_route_table_association" "myrta" {
 subnet_id = aws_subnet.sub1.id
 route_table_id = aws_route_table.myrt.id
}
resource "aws_route_table_association" "myrta1" {
 subnet_id = aws_subnet.sub2.id
 route_table_id = aws_route_table.myrt.id
}
resource "aws_security_group" "allow_tls" {
  name        = "mysg"
  vpc_id      = aws_vpc.myvpc.id
}

resource "aws_vpc_security_group_ingress_rule" "inboundrule" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "inboundrule1" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
resource "aws_vpc_security_group_egress_rule" "outboundrule" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}
resource "aws_s3_bucket" "mys3" {
  bucket = "yasmeen-first-bucket-from-teraform"
}
resource "aws_s3_bucket_public_access_block" "mybucketaccess" {
  bucket = aws_s3_bucket.mys3.id
  block_public_acls       = true
  block_public_policy     = false
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_versioning" "s3version" {
  bucket = aws_s3_bucket.mys3.id
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_instance" "ec21a" {
  ami = var.ami
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  subnet_id = aws_subnet.sub1.id
  user_data = base64encode(file("userdata.sh"))
}
resource "aws_instance" "ec21b" {
  ami = var.ami
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_tls.id]
  subnet_id = aws_subnet.sub2.id
  user_data = base64encode(file("userdata1.sh"))
}
resource "aws_lb" "myalb" {
  name               = "myalb"
  internal           = false
  load_balancer_type = "application"
  security_groups = [aws_security_group.allow_tls.id]
  subnets            = [aws_subnet.sub1.id, aws_subnet.sub2.id]
}
resource "aws_lb_target_group" "albtg" {
  name     = "alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.myvpc.id
  health_check {
    path = "/"
    port = "traffic-port"
  }
}
resource "aws_lb_target_group_attachment" "albtga" {
  target_group_arn = aws_lb_target_group.albtg.arn
  target_id        = aws_instance.ec21a.id
  port             = 80
}
resource "aws_lb_target_group_attachment" "albtga1" {
  target_group_arn = aws_lb_target_group.albtg.arn
  target_id        = aws_instance.ec21b.id
  port             = 80
}
resource "aws_lb_listener" "alblistener" {
  load_balancer_arn = aws_lb.myalb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.albtg.arn
  }
}
