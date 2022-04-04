data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./zipThis"
  output_path = "./lambdas/${var.zip_filename}"
}
