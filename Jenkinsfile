pipeline {
  agent any
  options { timestamps() }

  stages {
    stage('checkout') {
      steps {
        deleteDir() // clean workspace to avoid stale refs
        git branch: 'main', url: 'https://github.com/divyamohan1993/docker'
      }
    }

    stage('build') {
        steps {
          script {
            env.GIT_COMMIT = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
          }
          sh 'bash shell.sh'
        }
    }


    stage('test') {
      steps {
        sh '''
          set -euxo pipefail
          # Wait up to 30s for :5000 to respond
          for i in $(seq 1 30); do
            if command -v curl >/dev/null 2>&1 && curl -fsS http://localhost:5000/ >/dev/null; then exit 0; fi
            if command -v wget >/dev/null 2>&1 && wget -qO- http://localhost:5000/ >/dev/null; then exit 0; fi
            sleep 1
          done
          echo "Service on :5000 did not become ready in 30s" >&2
          (command -v ss >/dev/null && ss -tlnp || netstat -tlnp) || true
          pgrep -af python || true
          exit 1
        '''
      }
    }

    stage('deploy') {
      steps { sh 'true' } // placeholder
    }
  }
}
