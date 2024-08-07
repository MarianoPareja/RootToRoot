provider "aws" {
  region = "sa-east-1"
}

module "ecr" {
  source = "./modules/ecr"
}

module "django-backend-cluster" {
  source        = "./modules/django-backend-cluster"
  environment   = "dev"
  az_count      = 2
  instance_type = "t3.micro"
  ecr_url       = module.ecr.ecr-uri
  ecr_name      = module.ecr.ecr-name
}
