# Copyright 2022 Sean Kelleher. All rights reserved.
# Use of this source code is governed by an MIT
# licence that can be found in the LICENCE file.

FROM node:16.15.0

# We install `gridsite-clients` for use of the `urlencode` command.
RUN \
    apt-get update \
    && apt-get install \
        --assume-yes \
        gridsite-clients
