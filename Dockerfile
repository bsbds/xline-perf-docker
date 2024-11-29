FROM rust:1.74 AS builder

ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV RUSTFLAGS="-g -C force-frame-pointers=yes"
RUN apt-get update && apt-get install -y linux-perf git libclang-dev && \
    wget https://github.com/protocolbuffers/protobuf/releases/download/v21.10/protoc-21.10-linux-x86_64.zip && \
    unzip protoc-21.10-linux-x86_64.zip -d /usr/local

WORKDIR /usr/src/app
RUN git clone --recursive https://github.com/xline-kv/Xline.git .
RUN cargo build --release


FROM perf:latest

COPY --from=builder /usr/src/app/target/release/xline /xline 
COPY --from=builder /usr/src/app/target/release/benchmark /benchmark

WORKDIR /
