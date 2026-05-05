output "pipeline_names" {
  value = { for k, v in aws_codepipeline.service : k => v.name }
}

output "codebuild_project_names" {
  value = { for k, v in aws_codebuild_project.service : k => v.name }
}
