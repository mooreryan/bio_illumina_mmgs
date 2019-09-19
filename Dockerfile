FROM mooreryan/bio_base:0.2.0

LABEL maintainer="moorer@udel.edu"

ARG bindir=/usr/local/bin
ARG downloads=/home/downloads
ARG workdir=/home
ARG ncpus=4


# Need Java for Trimmomatic
RUN apt-get update && apt-get install -y openjdk-8-jre

WORKDIR ${downloads}

# FLASH is a dependency of the QC pipeline
RUN wget 'http://ccb.jhu.edu/software/FLASH/FLASH-1.2.11-Linux-x86_64.tar.gz'
RUN tar xzf FLASH-1.2.11-Linux-x86_64.tar.gz
RUN ln -s $(pwd)/FLASH-1.2.11-Linux-x86_64/flash ${bindir}/flash
RUN rm FLASH-1.2.11-Linux-x86_64.tar.gz

# Some ruby deps
RUN gem install bundler optimist abort_if systemu

# Install bowtie2 (for QC pipeline)
RUN wget 'https://github.com/BenLangmead/bowtie2/releases/download/v2.3.5.1/bowtie2-2.3.5.1-linux-x86_64.zip'
RUN unzip bowtie2-2.3.5.1-linux-x86_64.zip
RUN mv bowtie2-2.3.5.1-linux-x86_64/bowtie2* ${bindir}
RUN rm bowtie2-2.3.5.1-linux-x86_64.zip
# TODO it would be nice to build new bowtie indices for this....

# Install bbmap (for actual read mapping)
RUN wget -O BBMap_38.63.tar.gz 'https://sourceforge.net/projects/bbmap/files/BBMap_38.63.tar.gz/download'
RUN tar xzf BBMap_38.63.tar.gz
ENV PATH="${downloads}/bbmap:${PATH}"
RUN rm BBMap_38.63.tar.gz

# Install megahit
RUN wget 'https://github.com/voutcn/megahit/releases/download/v1.2.8/MEGAHIT-1.2.8-Linux-x86_64-static.tar.gz'
RUN tar zxf MEGAHIT-1.2.8-Linux-x86_64-static.tar.gz
RUN ln -s $(pwd)/MEGAHIT-1.2.8-Linux-x86_64-static/bin/megahit ${bindir}/megahit
RUN rm MEGAHIT-1.2.8-Linux-x86_64-static.tar.gz

# Install FastQC
RUN wget 'https://www.bioinformatics.babraham.ac.uk/projects/fastqc/fastqc_v0.11.8.zip'
RUN unzip fastqc_v0.11.8.zip
RUN rm fastqc_v0.11.8.zip
RUN chmod 755 FastQC/fastqc
RUN ln -s $(pwd)/FastQC/fastqc ${bindir}/fastqc

# Install QUAST
RUN wget -O quast-5.0.2.tar.gz 'https://sourceforge.net/projects/quast/files/quast-5.0.2.tar.gz/download'
RUN tar zxf quast-5.0.2.tar.gz
RUN rm quast-5.0.2.tar.gz
WORKDIR quast-5.0.2
RUN ./install.sh
ENV PATH="${downloads}/quast-5.0.2:${PATH}"
WORKDIR ${downloads}

# Install samtools
RUN wget -O samtools-1.9.tar.bz2 'https://sourceforge.net/projects/samtools/files/samtools/1.9/samtools-1.9.tar.bz2/download'
RUN tar xjf samtools-1.9.tar.bz2
RUN rm samtools-1.9.tar.bz2
WORKDIR samtools-1.9
RUN ./configure && make -j ${ncpus} && make install
WORKDIR ${downloads}

# Install QC pipeline
RUN wget 'https://github.com/mooreryan/qc/archive/v0.6.2.tar.gz'
RUN tar xzf v0.6.2.tar.gz
WORKDIR qc-0.6.2
RUN chmod 755 qc.rb qc_multilib_wrapper.rb
# Add to path as some of the paths it needs are hardcoded.
ENV PATH="/home/downloads/qc-0.6.2:${PATH}"
WORKDIR ${downloads}
RUN rm v0.6.2.tar.gz

# Install grep ids progam
RUN git clone https://github.com/mooreryan/grep_seqs.git
WORKDIR grep_seqs
RUN gcc grep_ids.c vendor/*.c -I./vendor -lz -Wall -g -O3 -o ${bindir}/grep_ids

## Get the FixPairs source code. (Needed if you use read screening in qc.rb)
RUN wget https://raw.githubusercontent.com/mooreryan/FixPairs/47064a2ca5709070c15df9098db2d97bfe937109/fix_pairs.cc
## It's a C++ program, so compile it.
RUN g++ -O2 -Wall --std=c++11 -o ${bindir}/FixPairs fix_pairs.cc

WORKDIR ${workdir}
