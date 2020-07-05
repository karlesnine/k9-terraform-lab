resource "aws_key_pair" "aws_ssh_key_name" {
  key_name   = var.aws_ssh_key_name
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC8j16q5ifBTxxNQkCHefoYX3xBG8rmISY8O/16/V480HXk0O5wnOVpeWjrb55yG6NtPOZh+FYW/gvgQyuX+RA2VhpeBkyU6GPQkt0cqg4IZIUk+mOc3198D21gKla1mBkAD3Ubjxu0wmkMNzZ367kmcCPtLdJFJXswcs1e1MX5rtJ+6w/K8mXkSvhryYu/ASJhB97mQ5xY596MaIj2ApRQiq4MG9r+9iyALXqOyHmmoHsmOioTaiYLo3fdNyRwlu68VFqcInolYY3KTxO2QR63vnMyVP/4AcrMdFUVtDAAuEwCj7vhAiLOfEkZec39DRUMPIET13PtoAMQDqYAorhIEtxMiTOpKJmEvi6JMvkZde2CPnaeGm67YR5quyODcwoFddc7/f153lBOzGmqfe+jenC/Cfzx0+bnoc3Z7yptId3vkECx4PiNKC/UHtZXfh7sgCVY36+3ibpyMXrxA10lRwGV+0EJIKSAdK3tzvVvJrXgZOEpIn7y7Y5P3xPTR6e5SSkvJ5nCSi1G8OknycKtRy8eeuKVRBpMHAZRupWzOJkbVNmcLU9I5BbernZwgZjyDyd7WBVY28zbsMQEjcjPrE1THmDc9DW7u87HnldrmfAenKmRYciC21NR5BT/ZgBh0v17x+MeMh1LYlzIuiDp9mU5rPwRZ7vMLbNXMIjeRw== karles@karlesnine.com"
  tags = {
    Name     = "karlesnine"
    Project  = var.your_project_name
  }
}

data "template_file" "userdata" {
  template = "${file("${path.module}/common/UserData-file/userData.tpl")}"
  vars = {
    s3_bucket_setting_name = "${var.s3_bucket_setting_name}"
  }
}


#
# MASTER
#
resource "aws_instance" "ec2_master" {
  # count = 1
  ami           = var.aws_ec2_ami
  instance_type = var.aws_ec2_instance_type
  key_name      = var.aws_ssh_key_name
  # user_data     = file("${path.module}/common/files/userData.tpl")
  user_data = data.template_file.userdata.rendered
  monitoring                  = false
  associate_public_ip_address = true
  source_dest_check           = true
  # iam_instance_profile        = ""
  ebs_optimized               = true
  iam_instance_profile = aws_iam_instance_profile.instance_setting_profile.name
   depends_on = [
     aws_s3_bucket.s3-setting-bucket,
     aws_iam_instance_profile.instance_setting_profile,
     aws_security_group.swarm_manager
    ]

  connection {
    type     = "ssh"
    user = "ubuntu"
    host     = self.public_ip
  }

  security_groups = [
    aws_security_group.swarm_manager.name,
    aws_default_security_group.default.name,
    aws_security_group.myip.name
  ]

  root_block_device {
    volume_type           = "standard"
    volume_size           = "8"
    delete_on_termination = "true"
  }

  lifecycle {
    ignore_changes = [user_data,ami]
    // If you need to protect the instance and do not destroy this it !
    prevent_destroy = false
  }

  tags = {
    Name     = "master0"
    Os       = "ubuntu"
    Project  = var.your_project_name
    Services = "node-exporter:docker"
  }

  volume_tags = {
    Name    = "master0"
    Project = var.your_project_name
  }
}

output "instance_public_ip_ec2_master" {
  value = "${formatlist(
    "%s = %s",
    aws_instance.ec2_master[*].tags.Name,
    aws_instance.ec2_master[*].public_ip
  )}"
  description = "public ip of ec2_master instance"
}


#
# WORKERS
# 
resource "aws_instance" "ec2_workers" {
  count = 2
  ami           = var.aws_ec2_ami
  instance_type = var.aws_ec2_instance_type
  key_name      = var.aws_ssh_key_name
  # user_data     = file("${path.module}/common/files/userData.tpl")
  user_data = data.template_file.userdata.rendered
  monitoring                  = false
  associate_public_ip_address = true
  source_dest_check           = true
  # iam_instance_profile        = ""
  ebs_optimized               = true
  iam_instance_profile = aws_iam_instance_profile.instance_setting_profile.name
   depends_on = [
     aws_s3_bucket.s3-setting-bucket,
     aws_iam_instance_profile.instance_setting_profile,
     aws_security_group.swarm_manager
    ]

  connection {
    type     = "ssh"
    user = "ubuntu"
    host     = self.public_ip
  }

  security_groups = [
    aws_security_group.swarm_manager.name,
    aws_default_security_group.default.name,
    aws_security_group.myip.name
  ]

  root_block_device {
    volume_type           = "standard"
    volume_size           = "8"
    delete_on_termination = "true"
  }

  lifecycle {
    ignore_changes = [user_data,ami]
    // If you need to protect the instance and do not destroy this it !
    prevent_destroy = false
  }

  tags = {
    Name     = "worker${count.index}"
    Os       = "ubuntu"
    Project  = var.your_project_name
    Services = "node-exporter:docker"
  }

  volume_tags = {
    Name    = "worker${count.index}"
    Project = var.your_project_name
  }
}

output "instance_public_ip_ec2_workers" {
  value = "${formatlist(
    "%s = %s",
    aws_instance.ec2_workers[*].tags.Name,
    aws_instance.ec2_workers[*].public_ip,
  )}"
  description = "public ip of all ec2_workers instance"
}