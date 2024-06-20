pipeline {
    agent any

    environment {
        AWS_REGION = 'us-west-1' // Update with your AWS region
        GIT_CREDENTIALS = credentials('git_lemp_new') // Jenkins credentials ID for Git
    }

    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
        choice(name: 'action', choices: ['apply', 'destroy'], description: 'Select the action to perform')
    }

    stages {
        stage('Deploy Infrastructure') {
            when {
                anyOf {
                    branch 'main'
                    branch 'staging'
                }
            }
            steps {
                script {
                    // Assume Jenkins Role for Terraform
                    def assumeRoleOutput = sh(
                        script: """
                            aws sts assume-role \\
                                --role-arn arn:aws:iam::372666185803:role/proviosned-role-for-jenkins-to-assume \\
                                --role-session-name jenkins-session \\
                                --output json
                        """,
                        returnStdout: true
                    ).trim()

                    // Parse JSON output to retrieve credentials
                    def credentials = readJSON text: assumeRoleOutput
                    def awsAccessKeyId = credentials.Credentials.AccessKeyId
                    def awsSecretAccessKey = credentials.Credentials.SecretAccessKey
                    def awsSessionToken = credentials.Credentials.SessionToken

                    // Set AWS environment variables for this session
                    withEnv([
                        "AWS_ACCESS_KEY_ID=${awsAccessKeyId}",
                        "AWS_SECRET_ACCESS_KEY=${awsSecretAccessKey}",
                        "AWS_SESSION_TOKEN=${awsSessionToken}"
                    ]) {
                        // Checkout the GitHub repository using Jenkins Git credentials
                        git credentialsId: 'git_lemp_new', url: 'https://github.com/WaQQass/multibranch-staging-main-docker.git', branch: 'main'

                        // Terraform Init and Plan (for both staging and main)
                        dir('terraform') {
                            sh 'terraform init'
                            if (env.BRANCH_NAME == 'staging') {
                                sh 'terraform plan -out=tfplan'
                                sh 'terraform show -no-color tfplan > tfplan.txt'
                                
                            }
                        }

                        // Apply / Destroy based on parameters and branch
                        if (env.BRANCH_NAME == 'main') {
                            if (!params.autoApprove) {
                                def plan = readFile 'terraform/tfplan.txt'
                                input message: "Do you want to apply the plan?",
                                      parameters: [text(name: 'Plan', description: 'Please review the plan', defaultValue: plan)]
                            }
                            dir('terraform') {
                                sh 'terraform apply -input=false tfplan'
                                // Additional steps after apply for main branch
                                // Capture outputs, perform health checks, clone repo, install Docker, etc.
                            }
                        } else if (env.BRANCH_NAME == 'staging') {
                            // Validate Docker Compose configuration
                            echo "Validating Docker Compose configuration:"
                            sh 'docker-compose -f docker-compose.yml config -q'
                        } else {
                            error "Invalid branch detected: ${env.BRANCH_NAME}"
                        }
                    }
                }
            }
        }
    }
}
