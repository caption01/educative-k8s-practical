# setup aws credentail
export AWS_DEFAULT_REGION=ap-southeast-1
export AWS_ACCESS_KEY_ID=$(cat ./kops-creds | jq -r '.AccessKey.AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(cat ./kops-creds | jq -r '.AccessKey.SecretAccessKey')
export ZONES=ap-southeast-1a,ap-southeast-1b,ap-southeast-1c

# verify aws credentail
echo "user: $(aws sts get-caller-identity | jq ".Arn")"

# setup kops config
export NAME=devops23.k8s.local
export BUCKET_NAME=devops23-1703517098
export KOPS_STATE_STORE=s3://$BUCKET_NAME

# verify kops state store
echo "kops conf: $KOPS_STATE_STORE"

# create cluster
kops create cluster \
    --name $NAME \
    --control-plane-count 3 \
    --node-count 1 \
    --node-size t2.small \
    --control-plane-size t2.small \
    --zones $ZONES \
    --control-plane-zones $ZONES \
    --ssh-public-key ./cluster/devops23.pub \
    --networking kubenet \
    --kubernetes-version v1.24.17 \
    --yes


# get dns name
CLUSTER_DNS=$(aws elb \
    describe-load-balancers | jq -r \
    ".LoadBalancerDescriptions[] \
    | select(.DNSName \
    | contains (\"api-devops23\") \
    | not).DNSName")


# deploy go-demo-2
kubectl create \
    -f aws/go-demo-2.yml \
    --record --save-config

# set kube conf
export KUBECONFIG=$PWD/config/kubecfg.yaml

# delete cluster and bucket
kops delete cluster \
    --name $NAME \
    --yes

aws s3api delete-bucket \
    --bucket $BUCKET_NAME