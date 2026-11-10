# This is the "blueprint" for our container registry
resource "aws_ecr_repository" "devops_repo" {
  #checkov:skip=CKV_AWS_136: Accepted risk: AWS-managed default AES-256 encryption is sufficient for classroom testing demo images; customer-managed KMS key is omitted to prevent recurring KMS CMK costs.
  # The name for your repository
  name = "devops-repo"

  # This setting makes sure you can't accidentally overwrite an image tag
  image_tag_mutability = "IMMUTABLE"

  # This block enables vulnerability scanning when you push an image
  image_scanning_configuration {
    scan_on_push = true
  }

  # Tags are good practice for organization
  tags = {
    Environment = "Testing"
    ManagedBy   = "DevOps Class"
  }
}

# This "output" block will print the registry's URL after it's created
output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.devops_repo.repository_url
}
