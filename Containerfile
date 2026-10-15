FROM docker.io/library/ubuntu:24.04@sha256:33ceb71981b602c1a7443a53469e4dba065f7503eab3078a2d7a57a2ab987517

ENV DEBIAN_FRONTEND=noninteractive LANG=C.UTF-8
RUN apt-get update --snapshot 20261007T000000Z && apt-get install -y --no-install-recommends \
        build-essential ca-certificates curl git m4 unzip zstd opam python3 python3-pandas \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /opt/tools/bin && chown -R ubuntu:ubuntu /opt/tools

RUN --mount=type=bind,source=vendor/files,target=/opt/vendor/files \
    mkdir /opt/lean && tar --zstd -xf /opt/vendor/files/lean-4.24.1-linux.tar.zst -C /opt/lean --strip-components=1 \
    && unzip -q -j /opt/vendor/files/cvc5-1.4.0-Linux-x86_64-static.zip cvc5-Linux-x86_64-static/bin/cvc5 -d /opt/tools/bin \
    && tar xzf /opt/vendor/files/Isabelle2025-2_linux.tar.gz -C /opt --no-same-owner
COPY --chmod=755 bin/kodkodi /opt/tools/bin/kodkodi

USER ubuntu
WORKDIR /home/ubuntu
ENV PATH=/opt/tools/bin:/opt/lean/bin:/home/ubuntu/.opam/default/bin:$PATH

RUN opam init -y -a --bare --disable-sandboxing \
        default https://github.com/ocaml/opam-repository.git#8be50539770551c7731762640e5c7c39ae1666c1 \
    && opam switch create default ocaml-base-compiler.4.14.2 \
    && opam install -y dune.3.24.2 containers.3.18 containers-data.3.18 iter.1.9 menhir.20211128 \
        num.1.6 msat.0.8.3 tip-parser.0.6 \
    && opam clean -a -c -s --logs

RUN --mount=type=bind,source=vendor/files,target=/opt/vendor/files \
    mkdir -p /tmp/nunchaku /tmp/smbc \
    && tar xzf /opt/vendor/files/nunchaku-d23a876.tar.gz -C /tmp/nunchaku --strip-components=1 \
    && tar xzf /opt/vendor/files/smbc-9302783.tar.gz -C /tmp/smbc --strip-components=1 \
    && cd /tmp/nunchaku && opam exec -- dune build --profile=release src/main/nunchaku.exe \
    && install -m 755 _build/default/src/main/nunchaku.exe /opt/tools/bin/nunchaku \
    && cd /tmp/smbc && opam exec -- dune build --profile=release src/smbc.exe \
    && install -m 755 _build/default/src/smbc.exe /opt/tools/bin/smbc \
    && cd / && rm -rf /tmp/nunchaku /tmp/smbc

USER root
RUN chmod 755 /home/ubuntu
USER ubuntu
WORKDIR /artefact
