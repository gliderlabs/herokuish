FROM heroku/heroku:16

ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -qq \
 && apt-get install -yy -q daemontools ruby-dev build-essential \
 && apt-get -qq -y \
    --allow-downgrades \
    --allow-remove-essential \
    --allow-change-held-packages \
    dist-upgrade \
 && apt-get clean \
 && rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/* /var/tmp/*
RUN curl "https://github.com/gliderlabs/herokuish/releases/download/v0.3.35/herokuish_0.3.35_linux_x86_64.tgz" \
    --silent -L | tar -xzC /bin
RUN /bin/herokuish buildpack install \
	&& ln -s /bin/herokuish /build \
	&& ln -s /bin/herokuish /start \
	&& ln -s /bin/herokuish /exec
COPY include/default_user.bash /tmp/default_user.bash
RUN bash /tmp/default_user.bash && rm -f /tmp/default_user.bash
