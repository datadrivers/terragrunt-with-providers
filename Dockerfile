# Create builder layer
FROM alpine:3.11 as alpine-builder

# install extra tools
RUN apk update \
    && apk upgrade \
    && apk --no-cache add \
        curl

# Install TF Provider Nexus
FROM alpine-builder as TERRAFORM_PROVIDER_NEXUS-BUILD
ARG TERRAFORM_PROVIDER_NEXUS_VERSION=v1.10.2
ENV TERRAFORM_PROVIDER_NEXUS_CHECKSUM="5e9b8196eb98a3badf6ff094dafe197eb995537e433be307054271175e34cb19"
ENV TERRAFORM_PROVIDER_NEXUS_ARCHIVE_FILENAME=terraform-provider-nexus_${TERRAFORM_PROVIDER_NEXUS_VERSION}_linux_amd64.tar.gz
ARG TERRAFORM_PROVIDER_NEXUS_FILENAME=terraform-provider-nexus_${TERRAFORM_PROVIDER_NEXUS_VERSION}
ENV TERRAFORM_PROVIDER_NEXUS_URL=https://github.com/datadrivers/terraform-provider-nexus/releases/download/${TERRAFORM_PROVIDER_NEXUS_VERSION}/${TERRAFORM_PROVIDER_NEXUS_ARCHIVE_FILENAME}

RUN echo $TERRAFORM_PROVIDER_NEXUS_URL
RUN wget -q ${TERRAFORM_PROVIDER_NEXUS_URL} && \
    echo "${TERRAFORM_PROVIDER_NEXUS_CHECKSUM}  ${TERRAFORM_PROVIDER_NEXUS_ARCHIVE_FILENAME}" | \
    sha256sum -c - && \
    tar -zxvf ${TERRAFORM_PROVIDER_NEXUS_ARCHIVE_FILENAME} && \
    rm ${TERRAFORM_PROVIDER_NEXUS_ARCHIVE_FILENAME}

FROM hashicorp/terraform:0.13.2

ARG TERRAGRUNT=v0.24.0

RUN apk add --update --no-cache bash git openssh

ADD https://github.com/gruntwork-io/terragrunt/releases/download/${TERRAGRUNT}/terragrunt_linux_amd64 /usr/local/bin/terragrunt

RUN chmod +x /usr/local/bin/terragrunt

# add custom providers
COPY --from=TERRAFORM_PROVIDER_NEXUS-BUILD /terraform-provider-nexus_* /root/.terraform.d/plugins/linux_amd64/

# Add kubectl, aws_iam_auth for eks deployment
ARG KUBECTL=1.18.6
ARG AWS_IAM_AUTH=0.5.1

# Install kubectl (same version of aws esk)
RUN apk add --update --no-cache curl && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL}/bin/linux/amd64/kubectl && \
    mv kubectl /usr/bin/kubectl && \
    chmod +x /usr/bin/kubectl

# Install aws-iam-authenticator (latest version)
RUN curl -LO https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v${AWS_IAM_AUTH}/aws-iam-authenticator_${AWS_IAM_AUTH}_linux_amd64 && \
    mv aws-iam-authenticator_${AWS_IAM_AUTH}_linux_amd64 /usr/bin/aws-iam-authenticator && \
    chmod +x /usr/bin/aws-iam-authenticator

# Install eksctl (latest version)
RUN curl --silent --location "https://github.com/weaveworks/eksctl/releases/download/latest_release/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp && \
    mv /tmp/eksctl /usr/bin && \
    chmod +x /usr/bin/eksctl

WORKDIR /apps

ENTRYPOINT []
