data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./lambdas/${var.source_dir_path}"
  output_path = "./nodejs/node_modules/${var.zip_filename}"
}
