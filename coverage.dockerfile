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
                pip
RUN pip install gcovr

#Building proscess
RUN git clone https://github.com/frankjinn/verilator_LLM_Fuzzer.git
WORKDIR /
RUN mv verilator_LLM_Fuzzer verilator
WORKDIR /verilator

RUN unset VERILATOR_ROOT
RUN git pull

#Coverage report locaation
ARG rebuildTests=unknown
RUN mkdir coverage_tests coverage_reports
COPY queue ./coverage_tests

#Instrumentation flags
ENV CC=gcc
ENV CXX=g++
ENV CFLAGS=" -fprofile-arcs -ftest-coverage"
ENV CXXFLAGS=" -fprofile-arcs -ftest-coverage"
ENV LFLAGS="--coverage"
ENV VERILATOR_ROOT="/verilator"

#After changing src of verilator, rebuild from here
ARG rebuildVerilator=unknown

RUN autoconf
RUN ./configure
RUN make -j `nproc`

#Needed to run gcovr
ARG rebuildSetup=unknown
WORKDIR /verilator/src
RUN ./bisonpre -d -v -o verilog.c verilog.y
RUN cp verilog.c obj_opt/
RUN cp verilog.y obj_opt/
RUN rm -r obj_dbg