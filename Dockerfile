FROM python:3.12.3-slim-bookworm

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      locales \
      curl \
      libcairo2 \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libgdk-pixbuf-2.0-0 \
      libffi8 \
      libxml2 \
      libxslt1.1 \
      zlib1g \
      fonts-noto-core \
      fonts-freefont-ttf && \
    rm -rf /var/lib/apt/lists/*

RUN curl -L https://github.com/jgm/pandoc/releases/download/3.5/pandoc-3.5-1-$(dpkg --print-architecture).deb \
    -o /tmp/pandoc.deb && \
    dpkg -i /tmp/pandoc.deb && \
    rm /tmp/pandoc.deb

RUN pip install --no-cache-dir weasyprint==63.0

RUN mkdir -p /app /defaults /examples /in /out

COPY entrypoint.sh /usr/local/bin/hebrew-md-book
COPY defaults /defaults
COPY examples /examples

RUN chmod +x /usr/local/bin/hebrew-md-book

WORKDIR /app

ENV INPUT_DIR=/in \
    OUTPUT_DIR=/out \
    MD_PATTERN=*.md

ENTRYPOINT ["/usr/local/bin/hebrew-md-book"]

