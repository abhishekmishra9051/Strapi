terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.78.0"
    }
  }
  backend "azurerm" {

    resource_group_name  = "pt_abhi_backend_RG"
    storage_account_name = "abhibackendstorage"
    container_name       = "tfstate"
    key                  = "dev.terraform.tfstate"

  }

}

provider "azurerm" {
  features {

  }
}