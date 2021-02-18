FROM node:12-slim
WORKDIR /var

# install dependencies
RUN apt-get -y update && \
    apt-get -y install git-core && \
    apt-get -y install curl && \
    apt-get -y install unzip && \
    apt-get -y install jq

# install aws
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip -o awscliv2.zip && \
    ./aws/install

CMD /bin/bash
