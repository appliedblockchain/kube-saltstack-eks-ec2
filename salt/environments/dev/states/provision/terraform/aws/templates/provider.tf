provider "aws" {
  version = ">= {{ configs.provider.min_version }}"
  region  = "{{ configs.provider.region }}",
  access_key = "{{ configs.provider.access_key }}"
  secret_key = "{{ configs.provider.secret_key }}"
}
