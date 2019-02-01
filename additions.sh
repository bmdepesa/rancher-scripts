alias ls='ls -GFhl'
alias skc='set_kube_config'
alias rgl="kubectl get configmaps cattle-controllers -n kube-system -o json | jq -r '.metadata.annotations[\"control-plane.alpha.kubernetes.io/leader\"]' | jq -r '.holderIdentity'"

function set_kube_config {
  if [ -z $1 ]
  then
    echo "kubeconfig: $KUBECONFIG"
  else
    export KUBECONFIG=$1
  fi
}

function tugdel {
  if [ -z $1 ]
  then
    echo "Fuzzy name needed!"
  else
    tugboat droplets -a id | grep $1 | awk  -F',' '{print $2;}' | while read p; do tugboat destroy -c -i $p; done
  fi
}

function tugc {
  if [ -z $1 ]
  then 
    echo "Name is needed to create droplet!"
  else
    tugboat create $1 --keys=19891744
  fi
}

function tugls {
  tugboat droplets -i | grep "$1"
}

function rll {
  kubectl logs -n cattle-system $(rgl) $1
}

function agi_j {
  name_filter="$1"
  additional_adopts="$2"
  aws ec2 describe-instances \
  $additional_opts \
  --filters "Name=tag:Name,Values=$name_filter" \
  --output json | \
  jq -jr '.Reservations[].Instances[] | select((.State.Name=="running") or (.State.Name=="pending")) | { name: .Tags[] | select(.Key=="Name") | .Value, type: .InstanceType, id: .InstanceId, public: .PublicIpAddress, private: .PrivateIpAddress, state: .State.Name }'
}

function agi {
  agi_j $1 $2 | jq -r '"\(.name) \(.id) \(.type) \(.public) \(.private) \(.state)"'
}

function aws_delete {
  agi_j $1 $2 | jq -r '"\(.id)"' | while read p; do aws ec2 terminate-instances --instance-ids "$p"; done
}

# Set ami -- default ami is only in us-west-1
# Set keypair name
# Set subnet
# Set security groups
function aci {
  name=$1
  size=$2
  count=$3
  
  keyname="brandon-qa-aws-cali"
  sg="sg-07528f916a8214acd"
  subnet="subnet-73577c28"
  ami="ami-0e67a73eda9dabdeb"

  instances="$(aws ec2 run-instances \
    --image-id $ami \
    --count $3 \
    --instance-type $2 \
    --key-name $keyname \
    --security-group-ids $sg \
    --subnet-id $subnet \
    --block-device-mappings \
    "[{\"DeviceName\":\"/dev/sdf\",\"Ebs\":{\"VolumeSize\":20,\"DeleteOnTermination\":true}}]" | \
    jq -r '.Instances[] | { id: .InstanceId } | "\(.id)"')"
    echo $instances | while read instance; do aws ec2 create-tags --resources $instance --tags Key=Name,Value=$1; done
    echo "$instances"
}

# Creates an HA setup with Rancher installed
# kubectl must be installed - brew install kubernetes-cli
# aws cli must be installed - brew install awscli
# aws cli must be configured - aws configure
# jq must be installed - brew install jq
# kubectl / awscli / jq should be on your path
# lb should be setup w/ target group listeners
# target groups should be empty
# Create a folder for storing RKE files (ymlPath)
# Create a template at '%rke_files_path%/templates/ha-auto-template.yml' (template)
# nodes:
# - address: <addr1>
#   user: ubuntu
#   role: [controlplane,worker,etcd]
#   internal_address: <iaddr1>
# - address: <addr2>
#   user: ubuntu
#   role: [controlplane,worker,etcd]
#   internal_address: <iaddr2>
# - address: <addr3>
#   user: ubuntu
#   role: [controlplane,worker,etcd]
#   internal_address: <iaddr3>
# Set ARN for target groups
# Set hostname for rancher install
# Set a name for the generated rke yml file
function rancher_create_ha {
  # source vars
  ymlPath="/Users/bmdepesa/Dev/rke-yml/"
  template="templates/ha-auto-template.yml"
  yname="ha-new-test.yml"
  name="brandon-new-ha"
  hostname="brandon-ha-test.qa.rancher.space"
  t1="arn:aws:elasticloadbalancing:us-west-1:125601231307:targetgroup/brandonha2-tcp-80/f41acf8cdc80aa55"
  t2="arn:aws:elasticloadbalancing:us-west-1:125601231307:targetgroup/brandonha2-tcp-443/93410f6f74c31cf9"
  
  echo "Creating instances..."
  aci $name t2.medium 3
  
  echo "Getting instances information..."
  instances_raw="$(agi_j $name)"
  instances="$(echo $instances_raw | jq -r '"\(.id)"')"
  instances_public="$(echo $instances_raw | jq -r '"\(.public)"')"
  instances_private="$(echo $instances_raw | jq -r '"\(.private)"')"

  echo "Waiting for instances to be running..."
  echo $instances | while read instance; do aws ec2 wait instance-running --instance-ids $instance; done

  echo "Adding instances to target groups..."
  echo $instances | while read instance; do aws elbv2 register-targets --target-group-arn $t1 --targets Id=$instance ; done
  echo $instances | while read instance; do aws elbv2 register-targets --target-group-arn $t2 --targets Id=$instance ; done
  
  echo "Generating RKE yml..."
  cd $ymlPath
  cp $ymlPath$template $ymlPath$yname
  c=1
  echo $instances_public | while read public_ip; do sed -i "s/<addr$c>/$public_ip/g" ./$yname; c=$((c + 1)); done
  c=1
  echo $instances_private | while read private_ip; do sed -i "s/<iaddr$c>/$private_ip/g" ./$yname; c=$((c + 1)); done
  cat $ymlPath$yname

  echo "Waiting for Docker to be running..."
  sleep 60
  
  echo "Executing RKE"
  rke up --config $ymlPath$yname --ssh-agent-auth

  echo "Setting kubeconfig..."
  kc="kube_config_$yname"
  skc $ymlPath$kc

  echo "Installing Rancher via Helm"
  kubectl -n kube-system create serviceaccount tiller

  kubectl create clusterrolebinding tiller \
    --clusterrole cluster-admin \
    --serviceaccount=kube-system:tiller

  helm init --service-account tiller

  echo "Waiting for tiller..."
  sleep 60

  helm install stable/cert-manager \
    --name cert-manager \
    --namespace kube-system \
    --version v0.5.2

  helm install rancher-latest/rancher \
    --name rancher \
    --namespace cattle-system \
    --set hostname=$hostname \
    --set rancherImageTag=master
}