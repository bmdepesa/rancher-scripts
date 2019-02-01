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