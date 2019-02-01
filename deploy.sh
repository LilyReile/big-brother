#!/bin/bash
set -eu

bundle install --deployment

sam package --template-file template.yaml \
--output-template-file packaged-template.yaml \
--s3-bucket dylansreile-big-brother

sam deploy --template-file packaged-template.yaml \
--stack-name bigBrother \
--capabilities CAPABILITY_IAM
