pipeline {
    tools {
        maven 'Maven3.8.1'
    } 
    agent any
    stages {
        stage('Build') { 
            steps {
                sh 'mvn -B -DskipTests clean package' 
            }
        }
    }
}