Here is a full devops project to deploy my Asp.net core web app (news app) with mysql database in a full gitflow including 5 branches (test, dev, preprod, release) and the main branch to be the base code.
Using these technologies and tools:
- `GCP (Google Cloud Platform)`
- `Dotnet core 7`
- `Mysql`
- `Terraform`
- `Ansible`
- `Helm`
- `Jenkins`
- `Docker`
- `Kubernates`
- `Github`
## You can find all the detailed steps on the readme files on the following repos 👇🏽
## Infrastructure: https://github.com/mohamedsamirspot/Full-Devops-Project_Infrastructure
## Dotnet App: https://github.com/mohamedsamirspot/Full-Devops-Project_Dotnetcoreapp

# Full-Devops-Project_Infrastructure:
in this infrastructure we are going to prepair the gcp infra using terraform for our kubernates cluster to deploy our jenkins and our app to it.
![Image Description](Screenshots/Draw.io.jpg)
## GCP Infrastructure includes:
- 1 VPC
- Backend for saving the tfstate file of terraform
- 2 subnets (management subnet & restricted subnet):
- NAT gateway over the restricted subnet
- Management subnet has the following:
  - Public VM
- Restricted subnet has the following:
  - private standard GKE cluster (private control plane and private worker nodes)

Firstly creating the required service account for our terraform
![Image Description](Screenshots/1.png)
![Image Description](Screenshots/2.png)
![Image Description](Screenshots/3.png)
![Image Description](Screenshots/4.png)
![Image Description](Screenshots/5.png)
![Image Description](Screenshots/6.png)
![Image Description](Screenshots/7.png)

- Applying the terraform infrastructure code
  - firstly create the bucket first with all infra then uncomment the it and apply again
![Image Description](Screenshots/8.1.png)

            terraform init
            terraform apply

![Image Description](Screenshots/8.2.png)

  - for terraform init for the backend tfstate
  
      ![Image Description](Screenshots/9.png)
      
            gcloud auth application-default login
            terraform init -upgrade
  - Now remove your local terraform.tfstate and terraform.tfstate.backup files

- Creating my key to access the vm

      ssh-keygen -t rsa -f /home/spot/.ssh/myvmkey



![Image Description](Screenshots/10.1.png)

if you see this error

![Image Description](Screenshots/10.3.png)
empty this file (known_hosts)
![Image Description](Screenshots/10.2.png)
now copy the contents of the public key
![Image Description](Screenshots/11.png)
![Image Description](Screenshots/12.png)

  - Now navigate to this machine to put my public key file content

![Image Description](Screenshots/13.png)

- Now configure this vm using ansible to install the required tools (like gcloud (to work with the cluster), kubectl, helm, ...)
  --> [Ansible files](ansible-vm-preparation)

      ansible-playbook vm-preparation.yml
      
![Image Description](Screenshots/14.png)

- Build and push the jenkins slave dockerfile with all the required tools installed on it --> [Salve-Pod-Dockerfile](Salve-Pod-Dockerfile)
![Image Description](Screenshots/15.png)    

      docker build --build-arg JENKINS_PASSWORD=<myubuntu-jenkins-userpassword> -t mohamedsamirebrahim/enhanced-slave-image:latest -f Salve-Pod-Dockerfile .
      docker push mohamedsamirebrahim/enhanced-slave-image:latest


- Now ssh to this public vm from your local machine to begin the work
      
      gcloud compute ssh --zone "<zone_name>" "<privatevm_name>" --tunnel-through-iap --project "<project_id>"

- Connect to the cluster

      git clone https://github.com/mohamedsamirspot/Full-Devops-Project_Infrastructure

- Connect to the cluster

      gcloud container clusters get-credentials <privatecluster_name> --zone <zone_name> --project <project_id>

- Deploy jenkins infrastructure (master and slave) using ansible --> [Ansible Jenkins yaml files](Jenkins-Yaml-Files-With-Ansible)

      ansible-playbook ansible_jenkins.yaml

![Image Description](Screenshots/16.png)   
![Image Description](Screenshots/17.png) 

          kubectl get all -n jenkins

![Image Description](Screenshots/18.png)

- And now at this point we have our infrastructure up and running with jenkins and its slaves as deployment on our GKE cluster
- Now access master jenkins pod using the service loadbalancer ip

![Image Description](Screenshots/19.png)
![Image Description](Screenshots/20.png)

      kubectl exec -it jenkins-master-pod-name -n jenkins -- bash
      cat /var/jenkins_home/secrets/initialAdminPassword

![Image Description](Screenshots/21.png)

- preparing the branches of your app including the jenkins file, docker file and the helm chart to deploy the app

![Image Description](Screenshots/22.1.png)
![Image Description](Screenshots/22.2.png)
![Image Description](Screenshots/22.3.png)
![Image Description](Screenshots/22.4.png)

- Go to security and enable proxy compatibility

![Image Description](Screenshots/23.png)

- Now go to credentials and create username and password credential for the slave jenkins user that we created before in the dockerfile of the slave

![Image Description](Screenshots/24.png)
![Image Description](Screenshots/25.png)
![Image Description](Screenshots/26.png)
![Image Description](Screenshots/27.png)

- Now set up the jenkins agent (slave)

![Image Description](Screenshots/28.png)
![Image Description](Screenshots/29.png)
![Image Description](Screenshots/30.png)
![Image Description](Screenshots/31.png)
![Image Description](Screenshots/32.png)
![Image Description](Screenshots/33.png)
![Image Description](Screenshots/34.png)
![Image Description](Screenshots/35.png)

- Create dockerhub credential

![Image Description](Screenshots/36.png)
![Image Description](Screenshots/37.png)


- Get the kubeconfig from any of the connectors to the api-server (node or pod that runs this before gcloud container clusters get-credentials <privatecluster_name> --zone <zone_name> --project <project_id>)

        cat ~/.kube/config

![Image Description](Screenshots/38.png)

- now create a kubeconfig file with this content

![Image Description](Screenshots/39.png)

- then create a secretfile credential to use this kubeconfig file content on Jenkinsfile

![Image Description](Screenshots/40.png)
![Image Description](Screenshots/41.png)

create the database credential for mysql of type secret text
![Image Description](Screenshots/42.png)

connect to the slave pod and change /var/run/docker.sock permissions

      kubectl exec -it jenkins-slave-pod-name -n jenkins -- bash
      chmod 777 /var/run/docker.sock

create multibranch pipeline

![Image Description](Screenshots/43.png)
![Image Description](Screenshots/44.png)
![Image Description](Screenshots/45.png)
![Image Description](Screenshots/46.png)
![Image Description](Screenshots/47.png)
![Image Description](Screenshots/48.png)
![Image Description](Screenshots/49.png)
![Image Description](Screenshots/50.png)
![Image Description](Screenshots/51.png)
![Image Description](Screenshots/52.1.png)
![Image Description](Screenshots/52.2.png)
![Image Description](Screenshots/52.png)
![Image Description](Screenshots/53.png)
![Image Description](Screenshots/54.png)
![Image Description](Screenshots/55.png)
![Image Description](Screenshots/56.png)