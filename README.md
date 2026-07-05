# DevOps Demo Project

One coherent project, real tool usage, no tool soup. Every component below
exists because it solves a specific problem — be ready to explain why in an
interview.

**Stack:** Terraform -> Ansible -> Docker -> Jenkins -> ECR -> k3s (Kubernetes)
-> Helm -> Prometheus/Grafana

**Architecture in one line:** Terraform provisions two raw EC2 instances,
Ansible configures them (Jenkins on one, k3s on the other), Jenkins builds
your app image and pushes it to ECR, then deploys it to k3s via Helm, and
Prometheus/Grafana monitor the running app.

---

## Prerequisites on YOUR machine

- Terraform >= 1.5
- Ansible >= 2.14
- AWS CLI, configured with `aws configure` (needs an IAM user with
  EC2/VPC/IAM/ECR create permissions)
- An existing EC2 key pair in your target AWS region (create in AWS Console
  > EC2 > Key Pairs if you don't have one; download the `.pem`)
- Docker (for testing the app locally before it ever touches AWS)
- kubectl and Helm (to verify deployment from your laptop)

---

## Step 1 — Test the app locally first (don't skip this)

Never deploy code to a cluster you haven't run once locally. Cheapest place
to catch bugs.

```bash
cd app
docker build -t devops-demo-app:local .
docker run -p 5000:5000 devops-demo-app:local
curl http://localhost:5000/
curl http://localhost:5000/health
curl http://localhost:5000/metrics
```

---

## Step 2 — Provision AWS infra with Terraform

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set key_pair_name and my_ip

terraform init
terraform plan     # READ this output before applying, don't skip it
terraform apply
```

Note the outputs — you need them for every step after this:
```bash
terraform output
```

---

## Step 3 — Configure the servers with Ansible

```bash
cd ../ansible
cp inventory.ini.example inventory.ini
# edit inventory.ini: paste in app_server_public_ip and jenkins_server_public_ip
# from terraform output, and the path to your .pem key

# Wait ~30 seconds after terraform apply for SSH to be ready, then:
ansible-playbook -i inventory.ini playbook-app-server.yml
ansible-playbook -i inventory.ini playbook-jenkins-server.yml
```

The Jenkins playbook prints the initial admin password at the end — copy it.

---

## Step 4 — Finish Jenkins setup (one-time, via browser)

1. Visit `http://<jenkins_server_public_ip>:8080`
2. Paste the initial admin password
3. Install suggested plugins
4. Create your admin user
5. Add credentials: **Manage Jenkins > Credentials > System > Global > Add**
   - Kind: Secret file
   - ID: `kubeconfig`
   - File: the `k3s-kubeconfig-<app_server_ip>.yaml` file Ansible fetched to
     your local `ansible/` directory in Step 3 (edit it first — replace
     `127.0.0.1` with the app server's public IP)
6. Create a Pipeline job pointing at your git repo, using
   `jenkins/Jenkinsfile` as the pipeline script path
7. In the Jenkinsfile, replace `REPLACE_WITH_ECR_REPO_URL` with your real
   `terraform output ecr_repository_url` value (same edit needed in
   `helm/app-chart/values.yaml`)

---

## Step 5 — Run the pipeline

Click **Build Now** in Jenkins. It will:
1. Build the Docker image
2. Push it to ECR
3. Deploy it to k3s via Helm
4. Verify the rollout succeeded

Visit `http://<app_server_public_ip>:30080` to see it live.

---

## Step 6 — Install monitoring

From your laptop, using the kubeconfig you fetched in Step 3:

```bash
export KUBECONFIG=./ansible/k3s-kubeconfig-<app_server_ip>.yaml

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  -f monitoring/kube-prometheus-values.yaml \
  --namespace monitoring --create-namespace
```

Visit `http://<app_server_public_ip>:30300`, log in with `admin` /
`changeme123` (change this), and add a dashboard for your `flask-app` job to
show request count and latency from the app's `/metrics` endpoint.

---

## Step 7 — TEAR IT DOWN WHEN YOU'RE DONE

This is not optional. These instances bill by the hour whether you're using
them or not.

```bash
cd terraform
terraform destroy
```

Also manually check the AWS Console (EC2, ECR, VPC) after destroying —
`terraform destroy` only removes what's in the state file. If you created
anything by hand (e.g. ECR images), remove those separately.

---

## What to actually say about this project on your resume / in interviews

Don't just list the tool names. Say what problem each one solved:

- "Used Terraform instead of manual console clicks so the infra is
  reproducible and version-controlled."
- "Used Ansible for configuration management because Terraform provisions
  infra but doesn't configure software on it — that's a different job."
- "Chose k3s over EKS to avoid control-plane cost while still getting real
  Kubernetes/Helm experience."
- "Built a Jenkins pipeline so deployment isn't a manual, error-prone SSH
  session."
- "Added Prometheus/Grafana because a deployed app with no visibility into
  its health is a half-finished project."

If an interviewer asks "why not X tool" and your honest answer is "cost" or
"scope control," say that. It shows judgment. Don't pretend you used
something you didn't.
