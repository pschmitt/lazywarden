# hadolint ignore=DL3007
FROM alpine:latest AS bw
# hadolint ignore=DL4006,SC2035,DL3018
RUN apk add --no-cache curl jq unzip && \
    BW_URL=$(curl -H "Accept: application/vnd.github+json" \
      https://api.github.com/repos/bitwarden/clients/releases | \
      jq -er ' \
        [.[] | select(.name | test("CLI"))][0] | \
        .assets[] | select(.name | test("^bw-linux.*.zip")) | \
        .browser_download_url \
      ') && \
    curl -fsSL "$BW_URL" | funzip - > bw && \
    chmod +x ./bw


# hadolint ignore=DL3007
FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive

COPY --from=bw /bw /usr/local/bin/bw

# Update the package list and install necessary dependencies: curl, unzip, libsecret, jq, Python3, pip, virtualenv, and cron
# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      cron libsecret-1-0 \
      build-essential python3 python3-pip python3-venv python3-dev && \
    rm -rf /var/lib/apt/lists/*

# Copy the necessary files into the container
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY requirements.txt /app/requirements.txt
COPY .env /app/.env
COPY config/bitwarden-drive-backup-google.json /root/lazywarden/config/bitwarden-drive-backup-google.json

# Copy the application files to the container
COPY app/ /app/app/

# Create a virtual environment and install Python dependencies
RUN python3 -m venv /app/venv && \
    /app/venv/bin/pip install --no-cache-dir -r /app/requirements.txt && \
    chmod +x /usr/local/bin/entrypoint.sh

# Define the entrypoint to run the entrypoint.sh script when the container starts
ENTRYPOINT [ "/usr/local/bin/entrypoint.sh" ]
