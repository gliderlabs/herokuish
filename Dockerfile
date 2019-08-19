FROM heroku/heroku:18-build

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -qq \
 && apt-get install -qq -y daemontools \
 && cp /etc/ImageMagick-6/policy.xml /etc/ImageMagick-6/policy.xml.custom \
 && apt-get -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confnew \
    --allow-downgrades \
    --allow-remove-essential \
    --allow-change-held-packages \
    dist-upgrade \
 && mv /etc/ImageMagick-6/policy.xml.custom /etc/ImageMagick-6/policy.xml \
 && apt-get clean \
 && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /var/tmp/*
RUN curl "https://github.com/gliderlabs/herokuish/releases/download/v0.5.3/herokuish_0.5.3_linux_x86_64.tgz" \
    --silent -L | tar -xzC /bin
RUN /bin/herokuish buildpack install \
  && ln -s /bin/herokuish /build \
  && ln -s /bin/herokuish /start \
  && ln -s /bin/herokuish /exec
COPY include/default_user.bash /tmp/default_user.bash
RUN bash /tmp/default_user.bash && rm -f /tmp/default_user.bash
