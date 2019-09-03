FROM debian:buster AS build
LABEL maintainer="paulpalmes@ie.ibm.com"

WORKDIR /

RUN set -ex

RUN apt-get update --allow-releaseinfo-change && apt-get -y upgrade && \
	apt-get install -y tzdata git wget build-essential

RUN apt-get clean -y && apt-get autoremove -y && apt-get autoclean -y

RUN apt-get update --allow-releaseinfo-change && apt-get -y upgrade && \
	apt-get install -y r-cran-caret r-cran-randomforest r-cran-mass r-cran-e1071 r-cran-gam && \
	apt-get install -y r-cran-kernlab r-cran-nnet r-cran-gridextra r-cran-pls

RUN wget https://julialang-s3.julialang.org/bin/linux/x64/1.1/julia-1.1.1-linux-x86_64.tar.gz &&  tar xzvf julia-1.1.1-linux-x86_64.tar.gz

RUN git clone https://github.com/JuliaLang/PackageCompiler.jl.git
COPY main.jl /
RUN /julia-1.1.1/bin/julia -e 'using Pkg; pkg"up; add https://github.com/ppalmes/TSMLextra.jl.git PackageCompiler#sd-notomls"'
RUN /julia-1.1.1/bin/julia -e 'using TSMLextra, PackageCompiler; sysnew,sysold = compile_incremental(:TSMLextra;install=true); cp(sysnew,sysold,force=true)'

RUN apt-get -y clean
RUN apt-get -y remove build-essential
RUN rm /julia-1.1.1-linux-x86_64.tar.gz

##FROM gcr.io/distroless/cc
#FROM debian:buster
#WORKDIR /
#COPY --from=build /julia-1.1.1 /julia-1.1.1
#COPY --from=build /root/.julia /root/.julia
#ENV PATH="$PATH:/julia-1.1.1/bin"
#COPY tsmlextradockermain.jl /tsmlextradockermain.jl
#RUN chmod +x /tsmlextradockermain.jl
#ENTRYPOINT ["/tsmlextradockermain.jl"]
