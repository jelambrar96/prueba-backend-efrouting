data "local_file" "build_script" {
  filename = var.build_script_path
}

resource "null_resource" "build_and_push" {
  triggers = {
    build_script_content = data.local_file.build_script.content_md5
    ecr_repo_url         = var.ecr_repository_url
    image_tag            = var.image_tag
    force_rebuild        = var.force_rebuild
  }

  provisioner "local-exec" {
    command    = "bash ${var.build_script_path} ${var.aws_region} ${var.ecr_repository_url} ${var.image_tag}"
    on_failure = fail
  }
}

output "build_timestamp" {
  description = "Timestamp of when the build was executed"
  value       = null_resource.build_and_push.id
}
