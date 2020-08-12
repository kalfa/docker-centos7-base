FROM centos:7

######
# A Centos7 docker image which is able to test ADS python code using OpenAccess libs
# Python 3.6, OAScript 3.3
######

ARG EPEL_URL=http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
# ensure these values match those in DevOps-puppet:environment/production/data/common./yaml
ARG FLY_VERSION=linux_amd64_6.1.0
ARG VAULT_VERSION=linux_amd64_1.3.4

# It should be installed python, pip and python-dev for all the supported
# versions by the product and for which we need to build and test
# NOTE: python2.6 in Centos6 is not maintained anymore, so pip won't work well.
# Better installing other versions via pyenv and then use those, forgetting 2.6
# existence

# Install AgileAnalog repo
ADD agileanalog.repo /etc/yum.repos.d/agileanalog.repo
# Install WANdisco repository and gpg keys
ADD WANdisco-git.repo /etc/yum.repos.d/WANdisco-git.repo
RUN curl -s http://opensource.wandisco.com/RPM-GPG-KEY-WANdisco > /tmp/RPM-GPG-KEY-WANdisco
RUN rpm --import /tmp/RPM-GPG-KEY-WANdisco && rm /tmp/RPM-GPG-KEY-WANdisco
# install EPEL repo
RUN yum install -y ${EPEL_URL}
RUN yum update -y
# certificate-ca:
#	for pipeline script HTTPs verification
# gcc,gcc-c++,autotools,autotools,patch and other dev tools:
#	pyenv in order to compile python
# perl-devel, gettext and dev tools:
#	to compile git
# python:
#	tk-devel for tkinter
# bzip, readline:
#	for pyenv to run
# jq:
#	for concourse pipeline scripts
# libpng-devel freetype-devel:
#	build matlabplot in virtualenvironments (for ADS-process)
# openldap-devel:
#	for pip to be able to install lyldap
# rsync:
#	for concourse pipeline (see scripts in CICD repo's ci/*)
# which:
#	pipenv
# bash-completion:
#	general debug utility
# puppet(-agent):
#	this gives us puppet parser-validate
# git:
#	required by concourse pipenv scripts and ads-python-release.whl package
RUN yum -y install automake autotools \
	bash-completion bzip2 bzip2-devel \
	certificate-ca curl \
	freetype-devel \
	gcc gcc-c++ gettext \
	git \
	jq \
	libpng-devel \
	nfs-utils \
	openldap-devel \
	openssl openssl-devel \
	patch perl-devel \
	readline-devel rsync \
	ShellCheck sqlite sqlite-devel \
	tk-devel \
	wget \
	which \
	zlib-devel

# we need the fly binary to be able to control concourse pipelines
RUN mkdir -p /usr/local/bin
RUN wget --no-check-certificate -O /usr/local/bin/fly_${FLY_VERSION} https://intranet.aws.agileanalog.com/download/fly_${FLY_VERSION}
RUN chmod ugo+x /usr/local/bin/fly_${FLY_VERSION}
RUN ln -s /usr/local/bin/fly_${FLY_VERSION} /usr/local/bin/fly

# we need the vault binary to get passwords
RUN wget --no-check-certificate -O /usr/local/bin/vault_${VAULT_VERSION} https://intranet.aws.agileanalog.com/download/vault_${VAULT_VERSION}
RUN chmod ugo+x  /usr/local/bin/vault_${VAULT_VERSION}
RUN ln -s /usr/local/bin/vault_${VAULT_VERSION} /usr/local/bin/vault


# puppet agent in epel is ancient, 3.x, we want much newer, but newer than 6.13 fails on letsencrypt certs
RUN cd /tmp && wget https://yum.puppet.com/puppet6/puppet6-release-el-7.noarch.rpm && yum -y install puppet6-release-el-7.noarch.rpm && yum -y install puppet-agent-6.13.0-1.el7.x86_64

# once puppet agent is installed, we have ruby gem
RUN /opt/puppetlabs/puppet/bin/gem install puppet-lint



# <https://manuals.gfi.com/en/kerio/connect/content/server-configuration/ssl-certificates/adding-trusted-root-certificates-to-the-server-1605.html>
ADD AgileAnalogCA.pem /etc/pki/ca-trust/source/anchors/
RUN update-ca-trust force-enable
RUN update-ca-trust extract
