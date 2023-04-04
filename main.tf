# data "external" "lambda_build" {
#   program = ["bash", "-c", <<EOT
# (yarn run build) >&2
# EOT
#   ]
#   working_dir = "${path.module}/fn"
# }

resource "null_resource" "run_yarn_tsc" {
  provisioner "local-exec" {
    command = "cd ${path.module}/fn && yarn tsc"
  }
}
