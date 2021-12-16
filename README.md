# Integrating Regula with Bitbucket Pipelines
## Regula for IaC Security :handshake: Bitbucket Pipelines for Automation
### Introduction to Regula and Bitbucket Pipelines

#### Regula
[Regula](https://regula.dev/index.html) is a tool that evaluates infrastructure as code files for potential AWS, Azure, Google Cloud, and Kubernetes security and compliance violations prior to deployment.
Regula is an open source project maintained by [Fugue](https://www.fugue.co/) engineers.

#### Bitbucket Pipelines
[Bitbucket Pipelines](https://Bitbucket.org/product/features/pipelines) is an integrated CI/CD service built into Bitbucket. It allows you to automatically build, test, and even deploy your code based on a configuration file in your repository.

### Goal
Pair Regula's powerful, easy-to-use IaC scanning capabilities and Bitbucket Pipelines to automate the *secure* deployment of cloud infrastructure with terraform.

### Prerequisites
#### Bitbucket
- A Bitbucket account (either a Bitbucket cloud or Bitbucket server account)
- Multi-factor authentication enabled in your Bitbucket account
- Cloud provider account and credentials loaded into Bitbucket as [repository variables](https://support.atlassian.com/bitbucket-cloud/docs/variables-and-secrets/) (for this demonstration, I'll be using AWS)
- A Bitbucket repository (cloned locally) containing cloud resources declared with terraform (see below for how my repository is structured)

### What's in the repo?
![file structure](/img/tree.png "file structure")

What you see above is a visual representation of the file structure for the above repo, which most notably contains:

`main.tf`: gives provider information to terraform   

`ec2/instances.tf`: declares my AWS EC2 instance and and IAM instance profile role   

`.regula.yaml` (not depicted above): declares [how I want regula to be run](https://regula.dev/usage.html#init) and configured in this repository   

`bitbucket-pipelines.yml`: dictates how I want my pipeline to run and which docker images I need for my pipeline to run correctly   

### Creating the Bitbucket Pipeline configuration file

First, we'll create the `bitbucket-pipelines.yml` file that will dictate to Bitbucket how we want our pipeline to run. Note: Bitbucket Pipelines comes standard with many templates, but for this demonstration we'll create our own.   

Start by entering the following commands (modifying the `<bracketed>` commands accordingly) into your terminal:
   
```
cd <your git repository>
touch bitbucket-pipelines.yml
<your favorite text editor or IDE> bitbucket-pipelines.yml
```

Copy and paste the following into the `bitbucket-pipelines.yml` file:

```
pipelines:
default:
	- step:
		name: 1 - Initialize, Format, and Validate Terraform
		image: hashicorp/terraform
		script:
			- terraform init && terraform fmt
			- terraform validate
	- step:
		name: 2 - Scan Terraform Locally for Security and Compliance with CIS Benchmarks
		image: fugue/regula
		script:
			# Run in root directory first
			- regula run ./
			# Run in child directories next
			- regula run ./*/
	- step:
		name: 3 - Plan and Apply Secure, Valid Terraform
		image: hashicorp/terraform
		deployment: Production
		trigger: manual
		script:
			- terraform init
			- terraform plan
			- terraform apply -auto-approve
```

Let's go through this pipeline step by step. First, we let Bitbucket know that this is a pipeline and, in fact, the default pipeline (you can create a separate pipeline for pull requests, for different branches of the repo, and other reasons):

```
pipelines:
default:
```

I've opted to have the following steps run sequentially, but I can also opt for them to run in parallel by adding the `parallel` command in the column to the left of the steps.   

Next, I'll declare my first step, which uses the hashicorp terraform image to initialize terraform, adjust my terraform formatting to hashicorp canonical standards, and ensure the validity of my terraform (for example, ensuring I have declared all of my variables and modules):

```
- step:
	name: 1 - Initialize, Format, and Validate Terraform
	image: hashicorp/terraform
	script:
		- terraform init && terraform fmt
		- terraform validate
```

The second step in my pipeline harnesses the power of Regula by automatically detecting any IaC files (terraform, cloudformation, and kubernetes manifests) in the root or any child directories, and scanning every IaC file detected in my repository against CIS Benchmark standards (want to scan for other compliance families like HIPAA, NIST 800-53, SOC2, PCI DSS, CSA, or AWS WAF out of the box? Email sales@fugue.co):

```
- step:
	name: 2 - Scan Terraform Locally for Security and Compliance with CIS Benchmarks
	image: fugue/regula
	script:
		# Run in root directory first
		- regula run ./
		# Run in child directories next
		- regula run ./*/
```

The final step re-initializes terraform and engages the hashicorp terraform image again, because [each step in the Bitbucket pipeline runs a separate Docker container](https://support.atlassian.com/bitbucket-cloud/docs/configure-bitbucket-pipelinesyml/), so declared dependencies do not carry over between steps. The final step then creates a terraform plan and applies the plan:

```
- step:
	name: 3 - Plan and Apply Secure, Valid Terraform
	image: hashicorp/terraform
	deployment: Production
	trigger: manual
	script:
		- terraform init
		- terraform plan
		- terraform apply -auto-approve
```

Now let's see this pipeline in action!

#### Trying (and failing) a build
I begin by entering the following commands in my terminal after completing edits on my repository containing IaC files:

```
git add <files>
git commit -m "initiating the bitbucket pipeline"
git push
```

Upon detecting the new commit to my repository (or being manually commanded to do so), Bitbucket Pipelines will trigger the pipeline described in the `.yml` file above. See below for what happens when I try to commit to the main branch of the repository with terraform that violates CIS Benchmarks:

![failed build](/img/failed_build.gif "failed build")

#### Resolving configuration issues with Regula

Now that I know I have misconfigurations in my terraform files, I can go back into my repo in VSCode and execute a `regula run` locally to address those issues.
I set up this repository to allow me to un-comment my terraform code corrections easily, but properly configuring your infrastructure is as easy as clicking the [Fugue rule remediation documentation hyperlink](https://docs.fugue.co/remediation.html) that populates with every rule violation following a `regula run`.
See below for how I fixed Fugue rules `FG_R00253` and `FG_R00271`, then re-checked my infrastructure with a final `regula run`.

![fixing regula issues](/img/fixing_issues.gif "fixing issues")

#### Trying (and succeeding!) a build

With my infrastructure properly configured, I'll commit to my Bitbucket repository again to maximize the automation provided by the Bitbucket Pipeline I have configured for my repository (see below):

I'll re-run the commands I ran initially...
```
git add <files>
git commit -m "initiating the bitbucket pipeline"
git push
```
...resulting in a successful build:

![successful build](/img/successful_build.gif "successful build")

And that's it! Now we have a Regula/Bitbucket Pipeline to securely automate the deployment of cloud infrastructure using terraform.
