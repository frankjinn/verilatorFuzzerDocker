#Note to self, everything is automatically run under sudo
FROM ubuntu:22.04

RUN apt-get update
RUN apt-get -y install curl 

#Prereqs
RUN apt-get -y install \
                git help2man perl python3 make autoconf gcc g++ flex bison ccache \ 
                libgoogle-perftools-dev numactl perl-doc \
                libfl2 \
                libfl-dev \
                pip \
                afl mdm gcc-11-plugin-dev \
                python2 lcov 

RUN pip install gcovr
RUN apt-get install sudo
RUN sudo apt -y install build-essential clang llvm-dev make git python3 python3-pip

#Building AFL-clang-fast
RUN git clone https://github.com/AFLplusplus/AFLplusplus.git
WORKDIR /AFLplusplus
RUN make distrib
RUN sudo make install
RUN make
WORKDIR /


# Cloning required repositories
RUN git clone https://github.com/frankjinn/verilator_LLM_Fuzzer.git
RUN git clone https://github.com/mrash/afl-cov.git

WORKDIR /afl-cov
RUN cp afl-cov /usr/local/bin/

# Rename the directory
WORKDIR /
RUN mv verilator_LLM_Fuzzer verilator

# Set the working directory to the renamed folder
WORKDIR /verilator/nodist/fuzzer
RUN git pull

RUN unset VERILATOR_ROOT
RUN chmod +x ./
RUN ./all.sh

#Setting verilator root
ENV VERILATOR_ROOT=/verilator
WORKDIR /verilator
RUN AFL_HARDEN=1 CC=afl-clang-fast CXX=afl-clang-fast++ ./configure

#Coverage report location
ARG rebuildTests=unknown

