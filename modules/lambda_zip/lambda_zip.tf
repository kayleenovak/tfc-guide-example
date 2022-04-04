data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./canary/${var.source_dir_path}"
  output_path = "./canary/${var.zip_filename}"
}
