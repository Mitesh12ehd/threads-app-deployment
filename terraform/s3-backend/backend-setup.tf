provider "aws"{}

resource "aws_s3_bucket" "thread-app-terraform-bucket" {
    bucket = "thread-app-terraform-bucket-miteshch"

    tags = {
        Name = "thread-app-terraform-bucket"
    }
}

resource "aws_s3_bucket_versioning" "thread-app-s3-versioning" {
    bucket = aws_s3_bucket.thread-app-terraform-bucket.id
    versioning_configuration {
        status = "Enabled"
    }
}

resource "aws_s3_bucket_public_access_block" "thread-app-public-access-block" {
    bucket = aws_s3_bucket.thread-app-terraform-bucket.id

    block_public_acls = true
    ignore_public_acls = true
    block_public_policy = true
    restrict_public_buckets = true
}

# enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "thread-app-terraform-encryption" {
    bucket = aws_s3_bucket.thread-app-terraform-bucket.id
    rule{
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
        }
    }
}

resource "aws_dynamodb_table" "terraform-db-table" {
    name = "terraform-lock-table"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "LockID"
    attribute {
        name = "LockID"
        type = "S"
    }

    tags = {
        Name = "Terraform Lock Table"
    }
}