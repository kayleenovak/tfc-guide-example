data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./nodejs/${var.source_dir_path}"
  output_path = "./nodejs/${var.source_dir_path}/${var.zip_filename}"
}
