output "ecr-repository-uri" {
    value = aws_ecr_repository.thread-app-ecr.repository_url
}