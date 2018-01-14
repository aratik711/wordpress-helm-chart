#!/bin/bash
set -e

export MYSQL_CHART_NAME=apporbit-backend
export WP_CHART_NAME=apporbit-frontend
export VARNISH_CHART_NAME=apporbit-proxy

##### VARIABLES TO BE EDITED #################

##MYSQL variables
export mysqlRootPassword=rootpass123
export mysqlUser=wp-user
export mysqlPassword=wppass123
export mysqlDatabase=wordpress

##Wordpress variables
export wordpressUsername=myuser
export wordpressPassword=mypass123
export wordpressEmail=abc@example.com
export wordpressFirstName=john
export wordpressLastName=doe
export wordpressBlogName="My Blog"

#############################################

##### DEFAULT VARIABLES #####################

## MYSQL variables
export mysqlMountPath=$HOME/mysql-data
export mysqlPort=3306

## WORDPRESS variables
export wordpressMountPath=$HOME/wp-data

##Varnish Variables
export varnishConfig=varnish-vcl
export varnishNodePort=30080

############################################

## Function to install mysql, wordpress and varnish

install() {

if [ -z "$mysqlRootPassword" ] || [ -z "$mysqlUser" ] || [ -z "$mysqlPassword" ] || \
   [ -z "$mysqlDatabase" ] || [ -z "$mysqlMountPath" ] || \
   [ -z "$wordpressUsername" ] || [ -z "$wordpressPassword" ] || [ -z "$wordpressEmail" ] || \
   [ -z "$wordpressFirstName" ] || [ -z "$wordpressLastName" ] || [ -z "$wordpressBlogName" ] || \
   [ -z "$wordpressMountPath" ]; then

  echo 'ERROR: one or more variables are undefined'        
  exit 1

fi

if [ ! -d "$wordpressMountPath" ] && [ ! -d "$mysqlMountPath" ]; then

  echo "Creating $wordpressMountPath and $mysqlMountPath"
  mkdir $mysqlMountPath
  mkdir $wordpressMountPath

fi

## Create mysql deployment

envsubst < data/mysql-values.yaml > mysql/values.yaml

helm install --name $MYSQL_CHART_NAME mysql

kubectl rollout status deployment ${MYSQL_CHART_NAME}-mysql

## Create wordpress deployment

envsubst < data/wp-values.yaml > wordpress/values.yaml

helm install --name $WP_CHART_NAME wordpress

kubectl rollout status deployment ${WP_CHART_NAME}-wordpress

## Create varnish deployment

envsubst < data/default.vcl.tpl > data/default.vcl

kubectl delete configmap --ignore-not-found=true $varnishConfig
kubectl create configmap $varnishConfig --from-file=data/default.vcl

envsubst < data/varnish-values.yaml > varnish/values.yaml

helm install --name $VARNISH_CHART_NAME varnish

kubectl rollout status deployment ${VARNISH_CHART_NAME}-varnish


GREEN='\033[0;32m'
NC='\033[0m' # No Color
printf "\n"
echo "${GREEN}Wordpress blog is available at http://<IP>:30080 in the browser. Login with credentials $wordpressUsername:$wordpressPassword ${NC}"
printf "\n"

}

## Delete all the deployments

cleanup() {

helm del --purge  ${MYSQL_CHART_NAME} ${WP_CHART_NAME} ${VARNISH_CHART_NAME} || true

printf "\n"    
read -p "Do you want to delete the data folders $HOME/mysql-data and $HOME/wp-data (y/n)? " yn
case $yn in
   [Yy]* ) sudo rm -rf $HOME/mysql-data $HOME/wp-data; 
           echo "Deleted folder $HOME/mysql-data and $HOME/wp-data"
           break;;
   * ) exit;;
esac

}

## Function to scale wordpress deployment

scale_WP() {

if [ -z $1 ]; then

  echo 'Please pass the desired number of replicas for wordpress deployment'
  exit 1

else

  kubectl scale deployments/${WP_CHART_NAME}-wordpress --replicas=$1

  kubectl rollout status deployment ${WP_CHART_NAME}-wordpress

fi

}

if ! command -v helm >/dev/null; then

  echo 'Please install helm first'
  exit 1

elif [ -z "$MYSQL_CHART_NAME" ] || [ -z "$WP_CHART_NAME" ] || [ -z "$VARNISH_CHART_NAME" ]; then

  echo "Chart names undefined"
  exit 1

else

  "$@"  

fi
