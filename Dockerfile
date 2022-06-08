# build from the Ubuntu image
ARG UBUNTU_VERSION
FROM ubuntu:${UBUNTU_VERSION}
ARG DEBIAN_FRONTEND=noninteractive

ARG USERNAME
ARG USER_UID
ARG USER_GID

#create the mssql user
RUN groupadd --gid $USER_GID $USERNAME \
  && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME

# installing SQL server
RUN apt-get update \
  && apt-get install -y \
  sudo \
  wget \
  curl \
  iputils-ping \
  net-tools \
  software-properties-common \
  apt-transport-https \
  python3-pip \
  && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
  && chmod 0440 /etc/sudoers.d/$USERNAME

RUN pip install mssql-cli
RUN sed -i "s/python/python3/g" /usr/local/bin/mssql-cli

RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/20.04/mssql-server-2019.list)"
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
RUN curl https://packages.microsoft.com/config/ubuntu/20.04/prod.list | tee /etc/apt/sources.list.d/msprod.list
RUN apt-get update && apt-get install -y mssql-server

RUN ACCEPT_EULA=Y apt-get install -y --allow-unauthenticated mssql-tools unixodbc-dev
RUN echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile \
  && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc \
  && . ~/.bashrc

#creating directories
RUN mkdir /var/opt/sqlserver
RUN mkdir /var/opt/sqlserver/data
RUN mkdir /var/opt/sqlserver/log
RUN mkdir /var/opt/sqlserver/backup

# set permissions on directories
RUN chown -R mssql:mssql /var/opt/sqlserver
RUN chown -R mssql:mssql /var/opt/mssql

# switching to the mssql user
USER mssql

# starting SQL Server
CMD /opt/mssql/bin/sqlservr
