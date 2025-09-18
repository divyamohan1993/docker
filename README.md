# Jenkins CI/CD — Dockerized Flask (One-file Pipeline)

Spin up a **reproducible Jenkins Pipeline** that:
- builds a Docker image for this repo,
- runs the container on port **5000**,
- health-checks `GET /health` (expects `{"status":"OK"}`).

**Who is this for?**  
Anyone who wants a minimal, copy-paste CI/CD example that proves Jenkins + Docker work on a fresh VM, with **one required plugin** and a single Pipeline script.

---

## Repo at a glance

- `Dockerfile` → runs `gunicorn -b 0.0.0.0:5000 app:app`
- `requirements.txt` → must include `flask` and `gunicorn`
- `app.py` → binds `0.0.0.0:5000`, exposes `/health`

---

## Quick Start

### 1) On the Jenkins server (SSH) — copy/paste

```bash
# A) (Optional) Grab auto-config helpers
wget -O autoconfig.sh https://raw.githubusercontent.com/divyamohan1993/devops-shell-scripts/main/jenkins/autoconfig.sh
wget -O run-latest.sh https://raw.githubusercontent.com/divyamohan1993/devops-shell-scripts/main/maven-gradle-sanity/run-latest.sh
chmod +x autoconfig.sh run-latest.sh
sudo ./autoconfig.sh
./run-latest.sh || true   # optional: Java/Maven/Gradle sanity

# B) Install Docker (official repository)
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
| sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo docker run --rm hello-world || true

# C) Allow Jenkins to use Docker
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
````

> If you also use the shell on this host, log out/in so your session picks up the `docker` group.

---

### 2) In Jenkins UI — install the plugin

**Manage Jenkins → Plugins → Available**
Install **Docker Pipeline** (ID: `docker-workflow`).
Restart if prompted.

---

### 3) Create the Pipeline job (no Jenkinsfile needed)

**New Item → Pipeline → (name it) → OK**
**Pipeline → Definition:** *Pipeline script* → **paste the script below** → **Save** → **Build Now**

```groovy
pipeline {
  agent any
  options { timestamps() }
  environment {
    REPO   = 'https://github.com/divyamohan1993/docker'
    BRANCH = 'main'
    IMAGE  = "local/flask-app:${env.BUILD_NUMBER}"
    HEALTH = 'http://localhost:5000/health'
  }
  stages {
    stage('Checkout') {
      steps {
        deleteDir()
        git branch: env.BRANCH, url: env.REPO
      }
    }
    stage('Build Image') {
      steps {
        script {
          // Requires Docker installed on the agent and the Docker Pipeline plugin
          docker.build(env.IMAGE)
        }
      }
    }
    stage('Run & Test') {
      steps {
        script {
          docker.image(env.IMAGE).withRun('-p 5000:5000') { c ->
            sh '''
              set -e
              for i in $(seq 1 30); do
                curl -fsS '"${HEALTH}"' >/dev/null && exit 0 || sleep 1
              done
              echo "Healthcheck failed" >&2
              docker logs '"${c.id}"' || true
              exit 1
            '''
          }
        }
      }
    }
    stage('Deploy') {
      steps { sh 'true' } // placeholder for your deployment
    }
  }
}
```

---

## Verify

After a green build:

```bash
curl -fsS http://<JENKINS_NODE_IP>:5000/health
# expected: {"status":"OK"}
```

---

## Troubleshooting (short)

* **Permission denied to Docker** → add `jenkins` to `docker` group and restart Jenkins (`usermod -aG docker jenkins && systemctl restart jenkins`).
* **Healthcheck fails** → `docker ps -a` and `docker logs <container>`; confirm `requirements.txt` has `flask` + `gunicorn` and the app listens on `0.0.0.0:5000`.
* **Checkout finds no revision** → job must target branch `main`.

---

## How this helps

* **Proves the path** from Git → Build (Docker) → Run → Test with the smallest moving parts.
* **Copy-paste friendly**: one plugin, one Pipeline, standard Docker, zero custom Jenkins groovy libs.
* **Good base** to extend: add push to registry, multi-stage Dockerfile, or environment-specific deploys.
