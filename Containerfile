FROM docker.io/library/centos:7
MAINTAINER midu@redhat.com
#

# upgrading the image and installing packages to the container
RUN yum upgrade -y && yum upgrade -y && yum install epel-release -y && yum install squid -y
# trim a little
RUN yum autoremove -y
# creating the admin user
RUN useradd -ms /bin/bash admin
# adding the admin user to 'sudo' group
RUN usermod -a -G root admin
# sudoers.d/admin creation
RUN mkdir -p /etc/sudoers.d/ && echo "admin ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/admin
RUN chmod 044 /etc/sudoers.d/admin
# switching to admin user
USER admin
# switching to admin homedirectory
WORKDIR /home/admin


CMD /bin/bash -c '/usr/sbin/squid -f ${} ; /bin/bash'