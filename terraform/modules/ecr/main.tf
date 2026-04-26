resource "aws_ecr_repository" "thread-app-ecr" {
    name = "thread-app"
    image_tag_mutability = "MUTABLE"
    image_scanning_configuration {
        scan_on_push = true
    }

    tags = {
        Name: "thread-app-repo"
    }
}