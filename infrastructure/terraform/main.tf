provider "aws" {
  region = "sa-east-1"
}

module "network" {
  source = "./modules/network"
}

module "database" {
  source = "./modules/database"
}

module "compute" {
  source = "./modules/compute"
}
