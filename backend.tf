terraform {
    backend "s3" {
       bucket      = "ts-academy-state-file2"
       key         = "ts-academy-tfstate"
       region      = "us-east-1"
    }
}