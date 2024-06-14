output "lbdnsname" {
  value = aws_lb.myalb.dns_name 
}
output "ec2id1" {
  value = aws_instance.ec21a.id
}
output "ec2id2" {
  value = aws_instance.ec21b.id
}
output "ec2id1_ip" {
  value = aws_instance.ec21a.public_ip
}
output "ec2id2_ip" {
  value = aws_instance.ec21b.public_ip
}

