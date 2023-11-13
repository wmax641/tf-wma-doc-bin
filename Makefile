ACCOUNT=$(shell aws sts get-caller-identity --query 'Account' --output text)
BASE_NAME=$(shell basename $(CURDIR))
REGION="ap-southeast-2"

init:
	terraform init \
        -backend-config="bucket=tf-${ACCOUNT}" \
        -backend-config="key=${BASE_NAME}" \
        -backend-config="region=${REGION}"

inits3:
	@echo -n "Create s3 bucket: 'tf-${ACCOUNT}'?   [y/N] " && read ans && [ $${ans:-N} = y ]
	aws s3api create-bucket --bucket "tf-${ACCOUNT}" --region "${REGION}" --create-bucket-configuration LocationConstraint="${REGION}"

fmt:
	terraform fmt -write=true --recursive

validate:
	terraform validate

plan:
	terraform plan -input=false -out=tfplan-${ACCOUNT}

apply:
	terraform apply -input=false tfplan-${ACCOUNT}

destroy:
	terraform plan -destroy -input=false -out=tfplan-${ACCOUNT}
	terraform apply -input=false tfplan-${ACCOUNT}

