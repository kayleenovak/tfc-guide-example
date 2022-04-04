data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./nodejs"
  output_path = "./lambdas/${var.zip_filename}"
}
