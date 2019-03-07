FROM heroku/heroku:18-build

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -qq \
 && apt-get install -qq -y daemontools \
 && apt-get -qq -y \
    --allow-downgrades \
    --allow-remove-essential \
    --allow-change-held-packages \
    dist-upgrade \
 && apt-get clean \
 && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /var/tmp/*
RUN curl "https://github.com/gliderlabs/herokuish/releases/download/v0.5.0/herokuish_0.5.0_linux_x86_64.tgz" \
    --silent -L | tar -xzC /bin
RUN /bin/herokuish buildpack install \
  && ln -s /bin/herokuish /build \
  && ln -s /bin/herokuish /start \
  && ln -s /bin/herokuish /exec
COPY include/default_user.bash /tmp/default_user.bash
RUN bash /tmp/default_user.bash && rm -f /tmp/default_user.bash
