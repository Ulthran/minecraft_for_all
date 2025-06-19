#! /bin/bash

aws cloudformation deploy \
  --template-file minecraft-server.yaml \
  --stack-name MinecraftServer \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameter-overrides KeyPairName=minecraft-server-key BackupBucketName=ctbus-minecraft-backup

