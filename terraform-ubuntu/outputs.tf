output "instances" {
  description = "Per-instance details"
  value = {
    for name, inst in aws_instance.main : name => {
      instance_id = inst.id
      public_ip   = inst.public_ip
      private_ip  = inst.private_ip
      public_dns  = inst.public_dns
      ssh         = "ssh -i ~/.ssh/jek_id_ed25519_pem ubuntu@${inst.public_ip}"
    }
  }
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.ec2.id
}
