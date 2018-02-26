FROM kuzmenkov/docker-baseimage:latest


#Installation of nesesary package/software for this containers...
RUN echo "deb http://archive.ubuntu.com/ubuntu `cat /etc/container_environment/DISTRIB_CODENAME`-backports main restricted universe" >> /etc/apt/sources.list
RUN (echo "deb http://cran.mtu.edu/bin/linux/ubuntu `cat /etc/container_environment/DISTRIB_CODENAME`/" >> /etc/apt/sources.list && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9)

## Install some useful tools and dependencies for MRO
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	ca-certificates \
	curl \
        wget \
	&& rm -rf /var/lib/apt/lists/*

WORKDIR /home/docker

# Download, valiate, and unpack
RUN wget https://www.dropbox.com/s/xrkzdhm1cq0ll1q/microsoft-r-open-3.3.2.tar.gz?dl=1 -O microsoft-r-open-3.3.2.tar.gz \
&& echo "817aca692adffe20e590fc5218cb6992f24f29aa31864465569057534bce42c7 microsoft-r-open-3.3.2.tar.gz" > checksum.txt \
	&& sha256sum -c --strict checksum.txt \
	&& tar -xf microsoft-r-open-3.3.2.tar.gz \
	&& cd /home/docker/microsoft-r-open \
	&& ./install.sh -a -u \
	&& ls logs && cat logs/*

# Clean up
WORKDIR /home/docker
RUN rm microsoft-r-open-3.3.2.tar.gz \
	&& rm checksum.txt \
&& rm -r microsoft-r-open

# system libraries of general use
RUN apt-get update && apt-get install -y \
    sudo \
    pandoc \
    pandoc-citeproc \
    libcurl4-gnutls-dev \
    libcairo2-dev \
    libxt-dev \
    libssl-dev \
    libssh2-1-dev \
    libssl1.0.0 \
    libxml2-dev \
    libssl-dev

# system library dependency for the euler app
RUN apt-get update && apt-get install -y \
    libmpfr-dev \
    gfortran \
    aptitude \
    libgdal-dev \
    libproj-dev \
    g++ \
    gdebi-core\
    libicu-dev \
    libpcre3-dev\
    libbz2-dev \
    liblzma-dev \
    libnlopt-dev \
    build-essential

COPY Makeconf /usr/lib64/microsoft-r/3.3/lib64/R/etc/Makeconf

#wget https://www.dropbox.com/s/hl0vx1f6rpfgxrx/shiny-server-1.5.3.838-amd64.deb?dl=1 -O shiny-server-1.5.3.838-amd64.deb

RUN wget https://www.dropbox.com/s/zjydeqye63dm7ra/shiny-server-1.5.5.872-amd64.deb?dl=1 -O shiny-server-1.5.5.872-amd64.deb \
&& dpkg -i --force-depends shiny-server-1.5.5.872-amd64.deb \
          && rm shiny-server-1.5.5.872-amd64.deb && \
    R -e "install.packages(c('shiny', 'rmarkdown'), repos='https://cran.rstudio.com/')" \
          && mkdir -p /srv/shiny-server; sync  \
          && mkdir -p  /srv/shiny-server/examples; sync  
   # && rm -rf /var/lib/apt/lists/*

#COPY Makeconf /usr/lib64/microsoft-r/3.3/lib64/R/etc/Makeconf

RUN mkdir -p /etc/my_init.d
COPY startup.sh /etc/my_init.d/startup.sh
RUN chmod +x /etc/my_init.d/startup.sh

##Adding Deamons to containers
RUN mkdir /etc/service/shiny-server /var/log/shiny-server ; sync 
COPY shiny-server.sh /etc/service/shiny-server/run
RUN chmod +x /etc/service/shiny-server/run  \
    && cp /var/log/cron/config /var/log/shiny-server/ \
    && chown -R shiny /var/log/shiny-server \
    && sed -i '113 a <h2><a href="./examples/">Other examples of Shiny application</a> </h2>' /srv/shiny-server/index.html

    

# basic shiny functionality
RUN apt-get install -y ncbi-blast+ \
&& R -e "install.packages('devtools', repos='https://cran.r-project.org/')" \
&& R -e "source('https://bioconductor.org/biocLite.R'); biocLite(); biocLite('Biostrings')" \
&& sudo su - -c "R -e \"install.packages('miniUI', repos='https://cran.r-project.org/');options(unzip = 'internal'); devtools::install_github('daattali/shinyjs')\"" \
&& sudo su - -c "R -e \"options(unzip = 'internal'); devtools::install_github('rstudio/DT')\"" \
&& sudo su - -c "R -e \"options(unzip = 'internal'); devtools::install_github('kuzmenkov111/rBLAST')\"" \
&& R -e "install.packages('data.table', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('future', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('foreach', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('doParallel', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('foreach', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('shinythemes', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('fst', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('msaR', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('shinyWidgets', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('shinyjqui', repos='https://cran.r-project.org/')"  \
&& R -e "install.packages('shinycssloaders', repos='https://cran.r-project.org/')" 




#COPY shiny-server.conf /etc/init/shiny-server.conf
RUN mkdir /var/lib/shiny-server/bookmarks \
 && chown -R shiny:shiny /var/lib/shiny-server/bookmarks
 
#volume for Shiny Apps and static assets. Here is the folder for index.html(link) and sample apps.
VOLUME /srv/shiny-server
EXPOSE 3838



CMD ["/sbin/my_init"]
