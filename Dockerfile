FROM phusion/passenger-ruby22

WORKDIR /home/app
ENV RAILS_ENV production

# Install mongodb
RUN echo 'deb http://downloads-distro.mongodb.org/repo/ubuntu-upstart dist 10gen' >> /etc/apt/sources.list && \
    apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10 && \
    apt-get -y update && \
    apt-get -y install mongodb-10gen=2.4.6 && \
    chsh -s /bin/sh mongodb
ADD mongod.runit /etc/service/mongod/run

# Install app
RUN npm install -g bower && \
    su app -c 'git clone https://github.com/fhir-crucible/crucible.git && \
               cd crucible && \
               git checkout origin/dstu2 && \
               bundle install --path vendor/bundle && \
               bower install'

# Set up app (requires mongo running)
RUN su mongodb -c 'mongod --fork --config /etc/mongodb.conf' && \
    su app -c 'cd crucible && rake assets:precompile'

# Configure nginx
RUN cd crucible && echo "env SECRET_KEY_BASE=$(rake secret);" > /etc/nginx/main.d/secret.conf && \
    rm -f /etc/nginx/sites-enabled/default /etc/service/nginx/down
ADD crucible.conf /etc/nginx/sites-enabled/
EXPOSE 80

# Set up delayed job
ADD delayed-job.rb /home/app/
ADD delayed-job.runit /etc/service/delayed-job/run

# Clean up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
