FROM ubuntu:bionic

LABEL org.label-schema.license="GPL-2.0" \
      org.label-schema.vcs-url="https://github.com/rocker-org/r-apt" \
      org.label-schema.vendor="Rocker Project" \
      maintainer="Dirk Eddelbuettel <edd@debian.org>"

## Set a default user. Available via runtime flag `--user docker` 
## Add user to 'staff' group, granting them write privileges to /usr/local/lib/R/site.library
## User should also have & own a home directory (for rstudio or linked volumes to work properly). 
RUN useradd -u 555 dockerapp\
    && mkdir /home/dockerapp\
    && mkdir /home/dockerapp/app \
    && mkdir /home/dockerapp/data \
    && mkdir /home/dockerapp/cashe \
    && mkdir /home/dockerapp/deleted \
    && chown -R dockerapp:dockerapp /home/dockerapp  \
    && addgroup dockerapp staff

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		software-properties-common \
                ed \
		less \
		locales \
		vim-tiny \
		wget \
		ca-certificates \
        && add-apt-repository --enable-source --yes "ppa:marutter/rrutter3.5" \
	&& add-apt-repository --enable-source --yes "ppa:marutter/c2d4u3.5" 

## Configure default locale, see https://github.com/rocker-org/rocker/issues/19
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
	&& locale-gen en_US.utf8 \
	&& /usr/sbin/update-locale LANG=en_US.UTF-8

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8

## This was not needed before but we need it now
ENV DEBIAN_FRONTEND noninteractive

# Now install R and littler, and create a link for littler in /usr/local/bin
# Default CRAN repo is now set by R itself, and littler knows about it too
# r-cran-docopt is not currently in c2d4u so we install from source
RUN apt-get update \
        && apt-get install -y --no-install-recommends \
                 littler \
 		 r-base \
 		 r-base-dev \
 		 r-recommended \
		 libcurl4-gnutls-dev \
		 libxml2-dev \
  	&& ln -s /usr/lib/R/site-library/littler/examples/install.r /usr/local/bin/install.r \
 	&& ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
 	&& ln -s /usr/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
 	&& ln -s /usr/lib/R/site-library/littler/examples/testInstalled.r /usr/local/bin/testInstalled.r \
 	&& install.r docopt \
 	&& rm -rf /tmp/downloaded_packages/ /tmp/*.rds \
 	&& rm -rf /var/lib/apt/lists/*

# basic shiny functionality
RUN apt-get update \
&& apt-get install -y ncbi-blast+

RUN R -e "install.packages('data.table', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('XML', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('jsonlite', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('stringi', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('stringr', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('dplyr', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('RCurl', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('BiocManager', repos='https://cran.r-project.org/')" \
&& R -e "BiocManager::install('GenomicRanges')" \
&& R -e "BiocManager::install('Biostrings')" \
&& R -e "install.packages('shiny', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('shinyjs', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('shinycssloaders', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('shinycustomloader', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('shinythemes', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('DT', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('fst', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('future', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('RColorBrewer', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('collapsibleTree', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('ggplot2', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('ggrepel', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('lemon', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('highcharter', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('shinyjqui', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('fs', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('gggenes', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('promises', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('ipc', repos='https://cran.r-project.org/')" \
&& R -e "install.packages('msaR', repos='https://cran.r-project.org/')"

VOLUME /home/dockerapp/data
VOLUME /home/dockerapp/task
VOLUME /home/dockerapp/cashe
VOLUME /home/dockerapp/deleted
EXPOSE 3838
USER dockerapp

CMD ["R", "-e shiny::runApp('/home/dockerapp/app',port=3838,host='0.0.0.0')"]
