A full devops project to deploy my Asp.net core web app (news app) with mysql database in a full gitflow including 5 branches (test, dev, preprod, release) and the main branch to contain the base code.
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


https://github.com/mohamedsamirspot/Full-Devops-Project_Infrastructure/assets/71722372/8ae2b7a6-e9e5-4de7-ad06-e16acdfdb530


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

- Creating my key to access the public vm (bastian host) using ssh for ansible

      ssh-keygen -t ed25519 -C  <remote-user-name> -f /Terraform-folderpath/full-devops-proj-bastian-host-key/<file-name>



![Image Description](Screenshots/10.1.png)



now copy the contents of the public key
![Image Description](Screenshots/11.png)
![Image Description](Screenshots/12.png)

  - Now put the public key content in the public vm creation key part

![Image Description](Screenshots/13.png)


- Now run the script.sh bash file to create the infra using terraform (including the bucket backend to store the state file) and configure the bastian host also using ansible and deploying the jenkins infra using ansible and helm

            ./script.sh

![Image Description](Screenshots/16.png)   
in case of you saw this error

![Image Description](Screenshots/10.3.png)

empty this file (known_hosts)

![Image Description](Screenshots/10.2.png)

![Image Description](Screenshots/8.2.png)

  - Now remove your local terraform.tfstate and terraform.tfstate.backup files you don't need them



- Build and push the jenkins slave dockerfile with all the required tools installed on it --> [Salve-Pod-Dockerfile](Salve-Pod-Dockerfile)
![Image Description](Screenshots/15.png)    

      docker build --build-arg JENKINS_PASSWORD=<myubuntu-jenkins-userpassword> -t mohamedsamirebrahim/enhanced-slave-image:latest -f Salve-Pod-Dockerfile .
      docker push mohamedsamirebrahim/enhanced-slave-image:latest



- Now ssh to this public vm to get the public ip of the jenkins service load balancer

          kubectl get all -n jenkins

![Image Description](Screenshots/18.png)

- And now at this point we have our infrastructure up and running with jenkins and its slaves as deployment on our GKE cluster
- Now access master jenkins pod using the service loadbalancer ip

![Image Description](Screenshots/19.png)
![Image Description](Screenshots/20.1.png)

      kubectl exec -it jenkins-master-pod-name -n jenkins -- bash
      cat /var/jenkins_home/secrets/initialAdminPassword

or just get it from logs
      
      kubectl logs jenkins-master-dep-6c68d86f64-qqvq2 -n jenkins

![Image Description](Screenshots/20.2.png)
![Image Description](Screenshots/20.3.png)

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

- then create a secretfile credential to use this kubeconfig file content on Jenkinsfile as the service account is working inside the pod w can create anything but it doesn't work inside the jenkins file so it is useless in our project 😞 it require a plugin

![Image Description](Screenshots/40.png)
![Image Description](Screenshots/41.png)

- create the database credential for mysql of type secret text (❗❗Note: must be in base 64 format)
- which will be passed in the jenkinsfile helm command as a value variable to be passed to the creation of the db-secret yaml file in the cluster, then to be passed to the app, database deployments containers
- in my case i will create 4 secrets one in each namespace and use it through the current env
![Image Description](Screenshots/42.png)

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