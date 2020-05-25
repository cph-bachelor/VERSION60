FROM phusion/passenger-ruby26:1.0.1

MAINTAINER murad@meew.dk and yemi@meew.dk

# Set correct environment variables.
ENV HOME /root

# Use baseimage-docker's init process.
CMD ["/sbin/my_init"]

# Additional packages: we are adding the netcat package so we can
# make pings to the database service
RUN apt-get update && apt-get install -y -o Dpkg::Options::="--force-confold" netcat

RUN apt-get update && apt-get install -y libldap2-dev
RUN apt-get update && apt-get install -y libidn11-dev

RUN apt-get update && apt-get install -y libpng-dev
RUN apt-get update && apt-get install -y --reinstall zlibc zlib1g zlib1g-dev

# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down

# Add virtual host entry for the application. Make sure
# the file is in the correct path
RUN rm /etc/nginx/sites-enabled/default
ADD omnipod.conf /etc/nginx/sites-enabled/omnipod.conf

# In case we need some environmental variables in Nginx. Make sure
# the file is in the correct path
ADD rails-env.conf /etc/nginx/main.d/rails-env.conf

# Install gems: it's better to build an independent layer for the gems
# so they are cached during builds unless Gemfile changes
WORKDIR /tmp
ADD Gemfile /tmp/
ADD Gemfile.lock /tmp/
RUN bundle install

# Copy application into the container and use right permissions: passenger
# uses the app user for running the application
RUN mkdir /home/app/omnipod
COPY . /home/app/omnipod
RUN usermod -u 1000 app
RUN chown -R app:app /home/app/omnipod
WORKDIR /home/app/omnipod


# Clean up APT when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

EXPOSE 80
