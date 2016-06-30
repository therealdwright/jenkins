FROM debian:jessie
MAINTAINER Dan Wright "dan.wright@simplehq.co"

# Why are we installing theses packages?
# git - obvious (SO WE CAN PULL THE SOFTWARES IN CASE CLARIFICATION NEEDED)
# make - used in jenkins jobs
# curl - used for installation process
# bsdtar - used for installation process
# software-common-properties - required to install add-apt-respository
RUN apt-get update && \
    apt-get install -y git make awscli npm m4 curl bsdtar && \
    apt-get --no-install-recommends install -q -y openjdk-7-jre-headless && \
    rm -rf /var/lib/apt/lists/*

# Install Jenkins 2.11
ADD http://mirrors.jenkins-ci.org/war/2.6/jenkins.war /opt/jenkins.war
RUN chmod 644 /opt/jenkins.war
ENV JENKINS_HOME /jenkins

# install packer as /usr/local/bin/packer
RUN curl https://releases.hashicorp.com/packer/0.10.1/packer_0.10.1_linux_amd64.zip | bsdtar -xvf - -C /usr/local/bin packer
RUN chmod +x /usr/local/bin/packer

RUN curl -sSL https://get.docker.com/ | sh
RUN curl -L https://github.com/docker/compose/releases/download/1.7.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
RUN chmod +x /usr/local/bin/docker-compose

ENTRYPOINT ["java", "-jar", "/opt/jenkins.war"]
EXPOSE 8080
CMD [""]
