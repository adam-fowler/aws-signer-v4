FROM swift:5.2 as builder

RUN apt-get -qq update && apt-get install -y \
  zlib1g-dev \
  && rm -r /var/lib/apt/lists/*

WORKDIR /aws-signer

# First just resolve dependencies.
# This creates a cached layer that can be reused
# as long as your Package.swift/Package.resolved
# files do not change.
COPY ./Package.* ./
RUN swift package resolve

COPY . .
RUN swift test
