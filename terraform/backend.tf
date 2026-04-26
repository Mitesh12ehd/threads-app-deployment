terraform {
    backend "s3" {
        bucket = "thread-app-terraform-bucket-miteshch"
        key = "thread-app/state.tfstate" // folder thread-app stores state.tfstate file
        region = "ap-south-1"
    }
}