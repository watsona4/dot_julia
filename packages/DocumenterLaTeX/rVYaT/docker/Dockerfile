# juliadocs/documenter-latex:0.1
FROM ubuntu:18.04
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && \
    apt-get install --no-install-recommends -qy \
    latexmk \
    texlive-latex-base \
    texlive-luatex \
    texlive-latex-recommended \
    texlive-latex-extra \
    fonts-lato \
    python-pygments \
    fontconfig && \
    rm -rf /var/lib/apt/lists/*
ADD https://api.github.com/repos/google/fonts/tarball/master google-fonts.tar.gz
RUN mkdir google-fonts /usr/share/fonts/robotomono/ && \
    tar xzf google-fonts.tar.gz --strip-components=1 -C google-fonts && \
    mv google-fonts/apache/robotomono/RobotoMono*.ttf /usr/share/fonts/robotomono/ && \
    rm -rf google-fonts google-fonts.tar.gz && \
    fc-cache -fv
RUN useradd -m zeptodoctor
WORKDIR /home/zeptodoctor/
