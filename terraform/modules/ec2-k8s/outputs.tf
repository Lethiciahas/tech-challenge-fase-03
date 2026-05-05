output "instance_id" {
  value = aws_instance.k8s_node.id
}

output "public_ip" {
  value = aws_eip.k8s_node.public_ip
}

output "private_ip" {
  value = aws_instance.k8s_node.private_ip
}

output "security_group_id" {
  value = aws_security_group.k8s_node.id
}

output "instance_profile_arn" {
  value = aws_iam_instance_profile.k8s_node.arn
}
