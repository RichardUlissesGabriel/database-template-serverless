#!/bin/bash
CLUSTER_IDENTIFIER=$(grep -A3 'clusterIdentifier:' ./infrastructure/serverless.yml | head -n1)
CLUSTER_IDENTIFIER=$(echo "$CLUSTER_IDENTIFIER" | sed -e "s/clusterIdentifier: //")
CLUSTER_IDENTIFIER=$(echo "$CLUSTER_IDENTIFIER" | sed -e "s/^[[:space:]]*//")

STAGE=$(git symbolic-ref --short -q HEAD)
INITIAL="false"
TEST="test"
HOMOLOG="homolog"
PROD="prod"

if [ "$STAGE" = "$TEST" ] || [ "$STAGE" = "$HOMOLOG" ] || [ "$STAGE" = "$PROD" ]
then
  STAGE=$STAGE
else
  if [ -z "$CI_COMMIT_REF_NAME" ]
  then
    STAGE="dev"
  else
    STAGE=$CI_COMMIT_REF_NAME
  fi
fi

{
  aws --version
} || {
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -o awscliv2.zip
  ./aws/install
  aws --version
}

{
  jq --version
} || {
  mkdir -p ~/bin && curl -sSL -o ~/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && chmod +x ~/bin/jq
  export PATH=$PATH:~/bin
  jq --version
}

#caso não exista a infraestrutura eu realizo o deploy
{
  aws ssm get-parameter --name /$CLUSTER_IDENTIFIER/$STAGE/PARAMETERS --with-decryption
} || {
  INITIAL="true"
  cd infrastructure
  npm i
  npm run deploy:$STAGE
  cd ..
}

PARAMETER_VALUE=$(printf '%s' $(aws ssm get-parameter --name /$CLUSTER_IDENTIFIER/$STAGE/PARAMETERS --with-decryption) | jq '.Parameter.Value')
PARAMETER_VALUE=$(echo $PARAMETER_VALUE | sed 's/\\//g')
PARAMETER_VALUE=$(echo $PARAMETER_VALUE | sed 's:^.\(.*\).$:\1:')
URL=$(printf '%s' $PARAMETER_VALUE | jq .url -r)
export DATABASE_URL=$URL

if [ $INITIAL = "true" ]
then
  npm i
  echo "Initial" | prisma migrate dev --schema=./prisma/schema.prisma --preview-feature
fi
