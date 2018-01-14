Scenario:

Create an shell/python script which when executed creates a three tier wordpress application on kubernetes. The three tiers are going to be,
 
Varnish
    ^
    |
Wordpress
    ^
    |
mysql
 
I should be able to scale wordpress tier directly using kubectl or shell/python script.

Description:

The apporbit project is used to deploy a simple 3 tier wordpress appication.
The backend will be mysql database (5.7.14), frontend will be wordpress application (4.9.1-r1) and proxy will be varnish (4).
The WP blog will be available on the kubernetes node port 30080. 


Presumptions:
Single node kubernetes cluster (Kubernetes v1.9.0+) on linux.
Internet should be accessible on the kube cluster.
The user with which the script will be run should have access to kubectl, helm and should have sudo rights.
The user should have a home directory with $HOME defined.
Varnish proxy runs on 80 port.
Wordpress runs on port 80.
Mysql runs on port 3306.
Tested on kubernetes node with 2CPU and 8GB memory.

Prerequisites:

Install helm with following commmands:

$ curl https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get > get_helm.sh
$ chmod 700 get_helm.sh
$ ./get_helm.sh

Install Tiller with following commmands:

$ helm init

After helm init, you should be able to run kubectl get pods --namespace kube-system and see Tiller running.

You can more details here: https://docs.helm.sh/using_helm/#installing-helm

Unzip the apporbit.zip in any directory on the kubernetes node and edit the install.sh file in apporbit directory.

unzip apporbit.zip

Edit the following variables:

##MYSQL variables
export mysqlRootPassword=rootpass123  ##root user password for mysql
export mysqlUser=wp-user ##Wordpress database user
export mysqlPassword=wppass123 ##Wordpress user password
export mysqlDatabase=wordpress ##Wordpress database

##Wordpress variables
export wordpressUsername=myuser ##Wordpress admin user
export wordpressPassword=mypass123 ##Wordpress admin password
export wordpressEmail=abc@example.com ##Wordpress admin email
export wordpressFirstName=john ##Wordpress admin user first name
export wordpressLastName=doe ##Wordpress admin user last name
export wordpressBlogName="My Blog" ## Wordpress blog name

Save and close.

1. To deploy the application execute the command:

sh install.sh install

The application will be available at http://<IP>:30080

2. To scale the Wordpress tier execute:

sh install.sh scale_WP <number of desired replicas>

ex: sh install.sh scale_WP 3
This will create 3 replicas of Wordpress deployment.

3. To cleanup the deployment execute:

sh install.sh cleanup

It will delete the helm releases and will ask if you want to delete the mysql and wordpress data directories.
Type in y/n as required.

If the data directory is not deleted then running the installation again will not change the mysql/wordpress credentials.
If the data directory is deleted all the mysql and wordpress data will be permenantly gone.

Known Issues/ Limitations:
1. Mysql and varnish deployments are not scalable.
2. Cleanup requires sudo rights.
3. Static ports for mysql, wordpress, varnish.
4. No custom configuration for mysql.
