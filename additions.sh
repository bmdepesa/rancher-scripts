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
    tugboat create $1 --keys=<>
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
  jq -r '.Reservations[].Instances[] | select(.State.Name=="running") | { name: .Tags[] | select(.Key=="Name") | .Value, type: .InstanceType, id: .InstanceId, public: .PublicIpAddress, private: .PrivateIpAddress }'
}

function agi {
  agi_j $1 $2 | jq -r '"\(.name) \(.id) \(.type) \(.public) \(.private)"'
}

function aws_delete {
  agi_j $1 $2 | jq -r '"\(.id)"' | while read p; do aws ec2 terminate-instances --instance-ids "$p"; done
}

function aci {
  name=$1
  size=$2
  count=$3
  ami=""
  key=""
  aws ec2 run-instances --image-id ami-xxxxxxxx --count 1 --instance-type t2.micro --key-name MyKeyPair --security-group-ids sg-903004f8 --subnet-id subnet-6e7f829e
}

function rancher_create_ha {
  # create instances
  # get instances
  # add to target group
  # create rke config
  # rke up
  # helm commands
  # set kubeconfig
}
