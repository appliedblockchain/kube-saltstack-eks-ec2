terraform {
  backend "s3" {
    bucket  = "{{ configs.terraform_backend.name }}"
    key     = "{{ configs.terraform_backend.key }}"
    region  = "{{ configs.terraform_backend.region }}"
    access_key = "{{ configs.terraform_backend.access_key }}"
    secret_key = "{{ configs.terraform_backend.secret_key }}"
    encrypt = true

  }
}
