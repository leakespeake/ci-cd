![jenkins](https://user-images.githubusercontent.com/45919758/281340934-3d6fb259-9fff-4707-8821-17d03ff00720.jpg)
# Jenkins CI/CD

Jenkins CI/CD - all Configuration as Code and setup at the heart of the automation tools and Jenkins pipelines.

## Overview
Jenkins is an automation server you can use to automate just about any task. It’s most often associated with building source code and deploying the results and is synonymous with continuous integration and continuous delivery **(CI/CD)**. Visit the *docker > docker-compose > jenkins* repo for full setup details. Official information below;

https://www.jenkins.io/

One of Jenkins’s most powerful features is its ability to distribute jobs across multiple nodes via a Controller (master) and Agent model. A Jenkins **controller** sends jobs to the appropriate **agent** based on the job requirements and the resources available at the time. A single Controller is fine for a homelab but you'd need additional agents in a production environment (utilizing agents offers enhanced safety and scalability).

---

## Plugins
Jenkins provides hundreds of **plugins** to support building, deploying and automating any project. Here we'll use the following plugins to create a powerful CI/CD environment;

- Jenkins Configuration as Code (define all config in a .YAML and commit to source control)
- Git (checkout our Jenkinsfile and associated code)
- Terraform (IaC deployments)
- Vault (consume secrets)
- Consul (remotely store our Terrform state file)
- vSphere (VM and Packer template creation)
- Packer (Packer template builds)
- Ansible (run playbooks)

For details on each plugin setup and operations - see the `README` within each individual plugin folder in this directory. Each will also have it's own `Jenkinsfile` for pipeline ops.

---

## Jenkins Durability
Pipelines are durable. If Jenkins crashes or restarts, the pipeline continues as its able to replay from disk via the last saved state. We can control this feature via the individual pipeline configuration under *General > Pipeline speed/durability override*.

Remember that Jenkins data is persisted via **$JENKINS_HOME** - the mount on the host VM (`/var/lib/docker/volumes/jenkins_jenkins-data/_data`) mapping to `/var/jenkins_home` in the Jenkins container - use `docker inspect jenkins` or `docker volume inspect jenkins_jenkins-data` for more. If we list this persistent data, notable files and directories are;

- config.xml (root configuration - if you edit a job here it won't reflect in the UI until Jenkins is reloaded)
- credentials.xml (credentials file, encrypted using the secret key from the secrets/ directory)
- secrets (secrets for credentials)
- plugins (plugins installed)
- jobs (directory for storing job files)
- workspace/* (job directories, one per job)

Via **Jenkins Configuration as Code**, using the dedicated Configuration as Code plugin, allows all Jenkins configuration to be orchestrated via a `.yaml` file, further adding to the resilience of Jenkins as a whole.

---

## Pipelines
We'll skip the use of a **Freestyle Project** since they can be a bit static and grow very long (backed by an .XML) and stick to a declarative **Pipeline** instead, via a Groovy based `Jenkinsfile`. NOTE: it's possible to convert a Freestyle to a Pipeline via the right plugin. More info at https://www.jenkins.io/doc/book/pipeline/

https://www.jenkins.io/doc/book/pipeline/syntax/ 

Creating a `Jenkinsfile` and committing it to source control provides a number of immediate benefits;

- Automatically creates a Pipeline build process for all branches and pull requests
- Code review/iteration on the Pipeline (along with the remaining source code)
- Audit trail for the Pipeline
- Single source of truth for the Pipeline, which can be viewed and edited by multiple members of the project

The following concepts are key aspects of Jenkins Pipeline, which tie in closely to Pipeline syntax;

- a **pipeline** block - a user-defined model of a CD pipeline (code defines your entire build process)
- a **node** block - a machine which is part of the Jenkins environment and is capable of executing a Pipeline
- a **stage** block - defines a distinct subset of tasks performed through the entire Pipeline
- a **step** block - a single task. A step tells Jenkins what to do at a particular point in time

A `Jenkinsfile` based Pipeline can either be created manually within VSC (tested) then committed to `SCM` (recommended), via `Blue Ocean` or via the `classic UI`(example used here). A Jenkinsfile created using the classic UI is stored by Jenkins itself ($JENKINS_HOME).

### Classic UI

*Dashboard > New Item > item name (avoid using spaces) > Pipeline*... Pipeline > Definition **[Pipeline script]** - enter script > Save > Build Now

### SCM (GitHub)
Your Pipeline’s `Jenkinsfile` can be written in VSC and committed to source control - optionally with the supporting code that Jenkins will build with (say Terraform .tf files). Jenkins can then check out your Jenkinsfile from source control as part of your Pipeline project’s build process and then proceed to execute your Pipeline.

*Dashboard > New Item > item name (avoid using spaces) > Pipeline*... Pipeline > Definition **[Pipeline script from SCM]** - then;

- SCM: Git
- Repository URL: https://github.com/leakespeake/ci-cd.git
- Credentials: (no credentials required when cloning from a public Git repo)
- Branches to build: (master or other)
- Script Path: /jenkins/vm-deployment-vsphere (where to find Jenkinsfile and related .tf files) - Jenkins will run the Jenkinsfile in the repo root by default
- Uncheck 'Lightweight checkout'
- Save
- Build Now

If using the `parameters {}` block in the Jenkinsfile, we will have a new option within the build job – **Build with Parameters** - example being;
```
    parameters {
        booleanParam(name: 'autoApprove', defaultValue: false, description: 'Automatically run apply after generating plan?')
    } 
```

Splitting up the `stages` is good for visualization and troubleshooting as we can easily see which stages failed or succeeded. 

If a build does fail, click into that particular run (example `#4`) then `Pipeline Steps` on the left – the status shows where the failure happened. Note that you can abort a build at any time by clicking into the build and on its Status page, click the RED X next to the Progress bar. 

All possible global variables that could be accessed in the pipeline script are listed at Pipeline Syntax > **Global Variables Reference** – like BRANCH_NAME , BUILD_ID etc

---

## Automatic Pipelines
Automating the build is a core component of Continuous Integration and Continuous Deployment.

### Build Triggers
Jenkins build triggers allow for the automation of builds and deployments based on specific events or conditions. We can add these via the `Build Triggers` section of the pipeline configuration page. Popular ones being;

- **Poll SCM** (`pulling trigger`) - a build will only be executed when any code changes are detected - a good starters option (pulling trigger). Just set a polling schedule > save... then a Git Polling Log link will appear in the job
- **GitHub hook trigger for GITScm polling** - (`pushing trigger`) - the build will be executed with the help of GitHub webhooks (the build process notified a change was made)
- **Build periodically** - schedule a time to periodically run the job

Benefits of using Jenkins build triggers include improved efficiency and productivity through an automated build processes and faster feedback loops for developers.

Find out more via the official Jenkins plugins index at https://plugins.jenkins.io/ and filter by Build triggers.

---

## Pipeline Troubleshooting
Refer to the **Icon Legend** link in the Dashboard for explainations of the colour keys for the build statuses (balls) and projects health (weather symbols denoting aggregates of multiple builds).

Click into your pipeline then under `Build History`, click on the job number (say `#23`) to see that specific build run overview page to check; 

- **Status** - user who started the build, individual pipeline stages (check the logs for the failed stage)
- **Console Output** – check the STDOUT build process to troubleshoot or verify success
- **Previous Build/Next Build** - (toggle between console output of other job builds)

### Surefire Reports
The `Maven Surefire Report Plugin` parses the generated TEST-*.xml files under ${basedir}/target/surefire-reports and renders them to create a web interface version of the test results. See here for more https://maven.apache.org/surefire/maven-surefire-report-plugin/

### VS Code – Jenkinsfile Validation
It can be a tedious workflow when you make a change to your `Jenkinsfile`, create a commit, push the commit, only for Jenkins Server to tell you there's a missing bracket. This also adds unnecessary git history with syntax fixes. However we can pre-test the `Jenkinsfile` via the **Jenkins Pipeline Linter Connector** for Visual Studio Code, prior to committing to source control. This VS Code extention takes the `Jenkinsfile` you have opened, pushes it to your Jenkins Server and displays the validation result in VS Code.

​You can find it from within the VS Code extension browser or at https://marketplace.visualstudio.com/items?itemName=janjoerke.jenkins-pipeline-linter-connector. Once installed we can click the extension cog symbol > extention settings... then populate the four entries below for VS Code to select the Jenkins server you want to use for validation;

- **jenkins.pipeline.linter.connector.url** the endpoint your Jenkins Server expects the POST request, containing your Jenkinsfile which you want to validate. Typically points to <your_jenkins_server:port>/pipeline-model-converter/validate

- **jenkins.pipeline.linter.connector.user** specify your Jenkins username

- **jenkins.pipeline.linter.connector.pass** specify your Jenkins password

- **jenkins.pipeline.linter.connector.crumbUrl** has to be specified if your Jenkins Server has `CRSF protection` enabled. Typically points to <your_jenkins_server:port>/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,%22:%22,//crumb)

Once added, from our open Jenkinsfile we can select: *View > Command Palette > Validate Jenkinsfile* and should either see **Jenkinsfile successfully validated** in the terminal or **Errors encountered validating Jenkinsfile** followed by details of the syntax issue.

### Misc Tips

BlueOcean – an alternate Jenkins UI that allows users to graphically create, visualize and diagnose pipelines. Not covered here due to following update;

> Blue Ocean will not receive further functionality updates. Blue Ocean will continue to provide easy-to-use Pipeline visualization, but it will not be enhanced further.

Try to centralize all your credentials (required by the builds) within Vault. Only add essential creds to the Jenkins credential manager (such as our approle Vault creds) to allow Jenkins to retrieve anything else it may need during a pipeline run. This ensures we don't duplicate credentials and use Vault for its intended purpose as the source of truth for our CI/CD secrets. We can do so via;

*Manage Jenkins > Credentials > Domains (global) > Add Credentials…*

---
