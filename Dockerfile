# Build image
# Build on mac m1, buildx giúp build đa nền tảng: docker buildx build --platform linux/amd64 -t IMAGE_NAME .
# Build trên linux có thể test: docker build -t IMAGE_NAME .

# FROM python:3.12.3-slim-bookworm as base
FROM --platform=linux/amd64 python:3.12.3-slim-bookworm as base

# Setup env
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONFAULTHANDLER 1
ENV PATH=/home/ftuser/.local/bin:$PATH
ENV FT_APP_ENV="docker"

# Prepare environment
RUN mkdir /freqtrade \
  && apt-get update \
  && apt-get -y install sudo libatlas3-base curl sqlite3 libhdf5-serial-dev libgomp1 -yqq wget unzip vim xclip \
  && apt-get -y install gnupg2 ca-certificates apt-transport-https software-properties-common \
  && apt-get -y install xvfb \
  && apt-get clean \
  && useradd -u 1000 -G sudo -U -m -s /bin/bash ftuser \
  && chown ftuser:ftuser /freqtrade \
  # Allow sudoers
  && echo "ftuser ALL=(ALL) NOPASSWD: /bin/chown" >> /etc/sudoers

# --- Start install selenium 6 chrome driver
# Install google chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
RUN sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
RUN apt-get -y update
RUN apt-get install -y google-chrome-stable

# Install chromedriver
RUN wget -O /tmp/chromedriver.zip https://storage.googleapis.com/chrome-for-testing-public/125.0.6422.76/linux64/chromedriver-linux64.zip
RUN unzip /tmp/chromedriver.zip chromedriver-linux64/chromedriver -d /usr/local/bin/

# Set display port to avoid crash
ENV DISPLAY=:99

# Upgrade pip
RUN pip install --upgrade pip

# Install selenium
RUN pip install selenium
# --- End install selenium 6 chrome driver

WORKDIR /freqtrade

# Install dependencies
FROM base as python-deps
RUN  apt-get update \
  && apt-get -y install build-essential libssl-dev git libffi-dev libgfortran5 pkg-config cmake gcc \
  && apt-get clean \
  && pip install --upgrade pip wheel

# Install TA-lib
COPY build_helpers/* /tmp/
RUN cd /tmp && /tmp/install_ta-lib.sh && rm -r /tmp/*ta-lib*
ENV LD_LIBRARY_PATH /usr/local/lib

# Install dependencies
COPY --chown=ftuser:ftuser requirements.txt requirements-hyperopt.txt /freqtrade/
USER ftuser
RUN  pip install --user --no-cache-dir numpy \
  && pip install --user --no-cache-dir -r requirements-hyperopt.txt

# Copy dependencies to runtime-image
FROM base as runtime-image

COPY --from=python-deps /usr/local/lib /usr/local/lib
ENV LD_LIBRARY_PATH /usr/local/lib

COPY --from=python-deps --chown=ftuser:ftuser /home/ftuser/.local /home/ftuser/.local

USER ftuser
# Install and execute
COPY --chown=ftuser:ftuser . /freqtrade/

RUN pip install -e . --user --no-cache-dir --no-build-isolation \
  && mkdir /freqtrade/user_data/ \
  && freqtrade install-ui

# Set display port as an environment variable for selenium run chrome headless
ENV DISPLAY=:99

ENTRYPOINT ["freqtrade"]
# Default to trade mode
CMD [ "trade" ]
