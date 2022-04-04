output "lambda_zip" {
  value = "${
    tomap({
      "output_path" = "${data.archive_file.lambda_zip.output_path}",
      "output_base64sha256" = "${data.archive_file.lambda_zip.output_base64sha256}"
    }
    )
  }"
}
