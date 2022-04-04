variable "zip_filename" {
  type        = "string"
  description = "the name of the zip file i.e. featureBranchLambda.zip"
}

variable "source_dir_path" {
  type        = "string"
  description = "the folder path inside the /lambdas source folder holding the files we need i.e. feature_branch -> /lambdas/feature_branch"
}
