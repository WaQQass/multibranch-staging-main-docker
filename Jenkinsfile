pipeline {
    agent any

    environment {
        AWS_REGION = 'us-west-1' // Update with your AWS region
        GIT_CREDENTIALS = credentials('git_lemp_new') // Jenkins credentials ID for Git
        REPO_URL = 'https://github.com/WaQQass/multibranch-staging-main-docker.git' // Replace with your repository URL
        BRANCH_NAME = "${env.GIT_BRANCH}"
    }

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
    }

    stages {
        stage('Checkout Code') {
            steps {
                script {
                    git branch: "${BRANCH_NAME}", credentialsId: 'git_lemp_new', url: "${REPO_URL}"
                }
            }
        }

        stage('Terraform Init and Plan') {
            steps {
                script {
                    dir('terraform') {
                        sh 'terraform init'
                        sh 'terraform plan -out=tfplan'
                        sh 'terraform show -no-color tfplan > tfplan.txt'
                    }
                }
            }
        }

        stage('Review Plan') {
            when {
                branch 'staging'
            }
            steps {
                script {
                    dir('terraform') {
                        def plan = readFile 'tfplan.txt'
                        input message: "Review Terraform Plan", parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                    }
                }
            }
        }

        stage('Validate Docker Compose') {
            when {
                branch 'staging'
            }
            steps {
                script {
                    sh '''
                        docker-compose -f docker-compose.yml config -q
                    '''
                }
            }
        }

        stage('Build Docker Images') {
            when {
                branch 'main'
            }
            steps {
                script {
                    dir('terraform') {
                        sh 'terraform apply -input=false tfplan'
                        sleep 15 // Wait for 15 seconds to ensure instance creation

                        // Capture the outputs
                        def outputs = sh(script: 'terraform output -json', returnStdout: true).trim()
                        echo "Terraform Outputs: ${outputs}"
                        writeFile file: 'outputs.json', text: outputs

                        // Parse JSON output and set environment variables
                        def outputJson = readJSON text: outputs
                        def instanceId = outputJson.instance_id.value
                        def publicIp = outputJson.public_ip.value

                        // Display the captured outputs
                        echo "Instance ID: ${instanceId}"
                        echo "Public IP: ${publicIp}"

                        // Health Check
                        echo "Performing health check on instance ${instanceId}"
                        timeout(time: 3, unit: 'MINUTES') {
                            waitUntil {
                                def statusCheck = sh(script: "aws ec2 describe-instance-status --instance-ids ${instanceId} --query 'InstanceStatuses[*].InstanceStatus.Status' --output text", returnStdout: true).trim()
                                def systemCheck = sh(script: "aws ec2.describe-instance-status --instance-ids ${instanceId} --query 'InstanceStatuses[*].SystemStatus.Status' --output text", returnStdout: true).trim()

                                if (statusCheck == 'ok' && systemCheck == 'ok') {
                                    echo "EC2 instance ${instanceId} passed both status checks."
                                    return true
                                } else {
                                    echo "EC2 instance ${instanceId} has not passed status checks yet. Waiting..."
                                    sleep 35 // Wait 35 seconds before checking again
                                    return false
                                }
                            }
                        }

                        // Wait for the SSM command to complete
                        sleep 30 // Adjust sleep time if necessary

                        // Clone the GitHub repository with Git credentials
                        echo "Cloning GitHub repository with credentials to instance ${instanceId}"
                        withCredentials([usernamePassword(credentialsId: 'git_lemp_new', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                            sh """
                                aws ssm send-command \
                                    --instance-ids ${instanceId} \
                                    --document-name "AWS-RunShellScript" \
                                    --parameters commands='["sudo apt-get install -y git", "git clone -b main https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/WaQQass/multibranch-staging-main-docker.git /home/ubuntu/tf.docker"]' \
                                    --region ${env.AWS_REGION}
                            """
                        }

                        // Wait for the SSM command to complete
                        sleep 120 // Adjust sleep time if necessary

                        // Install docker and docker-compose
                        echo "Installing docker and docker-compose on ${instanceId}"
                        sh """
                            aws ssm send-command \
                                --instance-ids ${instanceId} \
                                --document-name "AWS-RunShellScript" \
                                --parameters commands='["sudo apt update -y", "sudo apt install docker.io -y", "sleep 10", "sudo curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-\$(uname -s)-\$(uname -m) -o /usr/local/bin/docker-compose", "sudo chmod +x /usr/local/bin/docker-compose", "sudo docker-compose --version"]' \
                                --region ${env.AWS_REGION}
                        """

                        // Wait for the SSM command to complete
                        sleep 160 // Adjust sleep time if necessary

                        // Run Docker build and up commands
                        echo "Building image and running containers on ${instanceId}"
                        sh """
                            aws ssm send-command \
                                --instance-ids ${instanceId} \
                                --document-name "AWS-RunShellScript" \
                                --parameters commands='["cd /home/ubuntu/tf.docker && sudo docker-compose build && sleep 50 && sudo docker-compose up -d mysqldb && sleep 90 && sudo docker-compose up -d frontend_backend"]' \
                                --region ${env.AWS_REGION}
                        """
                        sleep 100 // Adjust sleep time if necessary
                    }
                }
            }
        }
    }
}
