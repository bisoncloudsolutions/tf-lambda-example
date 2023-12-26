data "archive_file" "function_handler" {
    type = "zip"
    source_dir = "function-handler"
    output_path = "function-handler.zip"
}

resource "aws_s3_bucket" "function_handler" {
    bucket = var.bucket_name
}

resource "aws_s3_bucket_object" "function_handler" {
    bucket = aws_s3_bucket.function_handler.id
    key = "function-handler.zip"
    source = data.archive_file.function_handler.output_path
    etag = filemd5(data.archive_file.function_handler.output_path)
}

data "aws_iam_policy_document" "lambda_assume"{
    statement {
        sid = "1"
        effect  = "Allow"
        actions = ["sts:AssumeRole"]

        principals {
            type = "Service"
            identifiers = ["lambda.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "lambda_execution" {
    name = "lambda-execution"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "function_handler" {
    function_name = "function-handler"
    s3_bucket = aws_s3_bucket.function_handler.id
    s3_key = aws_s3_bucket_object.function_handler.key

    runtime = "python3.9"
    handler = "lambda_function.lambda_handler"

    source_code_hash = data.archive_file.function_handler.output_base64sha256

    role = aws_iam_role.lambda_execution.arn
}
