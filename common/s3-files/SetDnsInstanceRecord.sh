#!/bin/bash
# (optional) You might need to set your PATH variable at the top here
# depending on how you run this script
#PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

#
# FOR RUN ON AMZ LINUX 1 - Elasticbeanstalk
# OR FOR Ubuntu >= 16;04
#

set -e

IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone | awk '{print substr($1, 0, length($1)-1)}')
ID_FROM_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 | cut -d "." -f3-4 | sed 's/\./-/g')
AUTO_SCALING_GROUP_NAME=$(aws ec2 describe-tags \
  --output text \
  --filters "Name=resource-id,Values=${INSTANCE_ID}" \
            "Name=key,Values=aws:autoscaling:groupName" \
  --region "${REGION}" \
  --query "Tags[*].Value")
ENV_NAME=$(aws ec2 describe-tags \
    --output text \
    --filters "Name=resource-id,Values=${INSTANCE_ID}" \
            "Name=key,Values=elasticbeanstalk:environment-name" \
    --region "${REGION}" \
    --query "Tags[*].Value")

# BUILD THE HOSTNAME
# Hostname come from tag name for ubuntu instance
# Hostname come from elasticbeanstalk env name and IP for elasticbeanstalk instance amz linux
#
if [ ! -z $AUTO_SCALING_GROUP_NAME ];
then
    if [ -z $ENV_NAME ]
    then
        NEWHOSTNAME="$AUTO_SCALING_GROUP_NAME-$ID_FROM_IP"
    else
        NEWHOSTNAME="$ENV_NAME-$ID_FROM_IP"
    fi
else
    NEWHOSTNAME=$(aws ec2 describe-tags --output text --filters "Name=resource-id,Values=$INSTANCE_ID" --region "$REGION" | grep -e "TAGS[[:space:]]*Name" | cut -f 5)
fi


# Hosted Zone ID e.g. BJBK35SKMM9OE
# In VC it's vcaws.com
ZONEID="Z0749049F7V9D4X8X30S"
# The CNAME you want to update e.g. hello.example.com
RECORDSET="$NEWHOSTNAME.aws.karlesnine.com"
# More advanced options below
# The Time-To-Live of this recordset
TTL=7200
# Change this if you want
COMMENT="Auto updating @ `date`"
# Change to AAAA if using an IPv6 address
TYPE="A"

function json_file {
    TMPFILE=$(mktemp /tmp/temporary-file.XXXXXXXX)
    cat > ${TMPFILE} << EOF
    {
      "Comment":"$COMMENT",
      "Changes":[
        {
          "Action":"UPSERT",
          "ResourceRecordSet":{
            "ResourceRecords":[
              {
                "Value":"$IP"
              }
            ],
            "Name":"$RECORDSET",
            "Type":"$TYPE",
            "TTL":$TTL
          }
        }
      ]
    }
EOF
}

function set_dns_record {
    # Update the Hosted Zone record
    aws route53 change-resource-record-sets --hosted-zone-id $ZONEID --change-batch file://"$TMPFILE"
}


json_file;
set_dns_record;