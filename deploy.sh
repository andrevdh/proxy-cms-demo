#! /bin/bash
# Docker / AWS Elasticbeanstalk deploy script - Andre van den Heever

CIRCLE_BUILD_NUM=$1
TIER=$2
BUILD_ENV=$3
PORT=$4
CONTAINER_MEM=$5
APPLICATION_NAME=$6
EB_BUCKET=cms-demo-$BUILD_ENV-$TIER
eval AWS_ACCESS_KEY_ID=\$aws_access_key_id_$BUILD_ENV
eval AWS_SECRET_ACCESS_KEY=\$aws_secret_access_key_$BUILD_ENV
export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION
export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
VERSION_LABEL="${CIRCLE_BUILD_NUM}-$TIER-$BUILD_ENV"


# aws command not picking up access variables, writing them to ~/.aws/config #
if [ ! -d ~/.aws ]
then mkdir ~/.aws
fi

# Create new AWS credentials file
echo -e "[$BUILD_ENV]\naws_access_key_id=$AWS_ACCESS_KEY_ID\naws_secret_access_key=$AWS_SECRET_ACCESS_KEY\nregion=eu-west-1" >> ~/.aws/credentials

# Create new Elastic Beanstalk version file
DOCKERRUN_FILE="${CIRCLE_BUILD_NUM}-$APPLICATION_NAME-$TIER-Dockerrun.aws.json"

# Use new multi container tempplate for production
sed -e "s/<TAG>/$CIRCLE_BUILD_NUM/g" \
    -e "s/<TIER>/$TIER/g" \
    -e "s/<PORT>/$PORT/g" \
    -e "s/<BUILD_ENV>/$BUILD_ENV/g" \
    -e "s/<EB_BUCKET>/$EB_BUCKET/g" \
    -e "s/<APPLICATION_NAME>/$APPLICATION_NAME/g" \
    -e "s/<CONTAINER_MEM>/$CONTAINER_MEM/g" < Dockerrun.aws.json.template > $DOCKERRUN_FILE

# Upload DOCKERZIP_FILE file to S3 bucket
s3cmd --access_key=$AWS_ACCESS_KEY_ID --secret_key=$AWS_SECRET_ACCESS_KEY put $DOCKERRUN_FILE s3://$EB_BUCKET/$DOCKERRUN_FILE

# Create new EB application version
aws elasticbeanstalk create-application-version --profile=$BUILD_ENV --application-name "$APPLICATION_NAME" \
  --version-label $VERSION_LABEL --source-bundle S3Bucket=$EB_BUCKET,S3Key=$DOCKERRUN_FILE --description "$APPLICATION_NAME $TIER, CI build number: $CIRCLE_BUILD_NUM"

# Slack notifications
SEND_SLACK() {
  MSG=$1
  curl -X POST --data-urlencode 'payload={"text": "'"$MSG"'"}' https://hooks.slack.com/services/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
}

# Wrapper function for any outbound build/deploy notifications
SEND_COMMS () {
  BUILD_LINK="https://circleci.com/gh/andrevdh/proxy-cms-demo/${CIRCLE_BUILD_NUM}"
  SEND_SLACK "$1 \n$BUILD_LINK"
}

# Deploy new application version to Elasticbeanstalk and clear Cloudflare cache
if [ $BUILD_ENV == "staging" ] || [ $BUILD_ENV == "production" ]
then
  aws elasticbeanstalk update-environment --profile=$BUILD_ENV --environment-name proxy-cms-demo-$BUILD_ENV-$TIER --version-label $VERSION_LABEL
  if [ $? -eq 0 ]
  then
    MESSAGE="Proxy CMS Demo Deployment to proxy-cms-demo-$BUILD_ENV-$TIER started"
    SEND_COMMS "$MESSAGE"
    TIMEOUT='0'
    while [ $TIMEOUT -lt 180 ]
    do EBCHECK=`aws elasticbeanstalk describe-environment-health --profile=$BUILD_ENV --environment-name proxy-cms-demo-$BUILD_ENV-$TIER --attribute-names Status --output text |awk '{ print $2 }'`
      if [ "$EBCHECK" = "Ready" ]
      then MESSAGE="Proxy CMS Demo Deployment to proxy-cms-demo-$BUILD_ENV-$TIER successful"
        SEND_COMMS "$MESSAGE"
        exit 0
      else
        sleep 10
        TIMEOUT=$[$TIMEOUT+10]
      fi
    done
  else
    MESSAGE="Proxy CMS Demo Deployment to proxy-cms-demo-$BUILD_ENV-$TIER failed"
    SEND_COMMS "$MESSAGE"
    exit 1#
  fi
fi
