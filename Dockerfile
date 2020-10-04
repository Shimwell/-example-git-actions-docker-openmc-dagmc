
FROM ubuntu:18.04

RUN apt-get --yes update && apt-get --yes upgrade

RUN apt-get -y install locales
RUN locale-gen en_US.UTF-8
ENV LC_CTYPE en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANG='en_US.UTF-8' LANGUAGE='en_US:en' LC_ALL='en_US.UTF-8'

# Install Packages Required
RUN apt-get --yes update && apt-get --yes upgrade
RUN apt-get --yes install gfortran 
RUN apt-get --yes install g++ 
RUN apt-get --yes install cmake 
RUN apt-get --yes install libhdf5-dev 
RUN apt-get --yes install git
RUN apt-get update

RUN apt-get install -y python3-pip
RUN apt-get install -y python3-dev
RUN apt-get install -y python3-setuptools
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apt-get install -y ipython3
RUN apt-get update
RUN apt-get install -y python3-tk

#Install unzip
RUN apt-get update
RUN apt-get install -y unzip

#Install Packages Optional
RUN apt-get --yes update
RUN apt-get --yes install imagemagick
RUN apt-get --yes install hdf5-tools
RUN apt-get --yes install paraview
RUN apt-get --yes install eog
RUN apt-get --yes install wget
RUN apt-get --yes install firefox
RUN apt-get --yes install dpkg
RUN apt-get --yes install libxkbfile1

#Install Packages Optional for distributed memory parallel simulations
RUN apt install --yes mpich libmpich-dev
RUN apt install --yes openmpi-bin libopenmpi-dev

RUN apt-get --yes install libblas-dev 
# RUN apt-get --yes install libatlas-dev 
RUN apt-get --yes install liblapack-dev

# needed to allow NETCDF on MOAB which helps with tet meshes in OpenMC
RUN apt-get --yes install libnetcdf-dev
RUN apt-get --yes install libnetcdf13


RUN apt-get --yes install libeigen3-dev

RUN rm /usr/bin/python
RUN ln -s /usr/bin/python3 /usr/bin/python


# Python Prerequisites Required
RUN pip3 install numpy
RUN pip3 install pandas
RUN pip3 install six
RUN pip3 install h5py
RUN pip3 install Matplotlib
RUN pip3 install uncertainties
RUN pip3 install lxml
RUN pip3 install scipy
RUN pip3 install pyvtk
RUN pip3 install cython


# newer CMake version allows us to set libraries, includes of the
# imported DAGMC target in CMake
RUN pip3 install cmake==3.12.0


# RUN apt-get --yes install mpich
# RUN apt-get --yes install libmpich-dev
# RUN apt-get --yes install libhdf5-serial-dev
# RUN apt-get --yes install libhdf5-mpich-dev
# RUN apt-get --yes install libblas-dev
# RUN apt-get --yes install liblapack-dev
# RUN apt-get --yes install bzip2
# RUN apt-get --yes install wget bzip2
# RUN apt-get -y install sudo #  needed as the install NJOY script has a sudo make install command
# RUN apt-get -y install git



# Clone and install NJOY2016
RUN git clone https://github.com/njoy/NJOY2016 /opt/NJOY2016 && \
    cd /opt/NJOY2016 && \
    mkdir build && cd build && \
    cmake -Dstatic=on .. && make 2>/dev/null && make install


#ENV DAGMC_DIR=$HOME/DAGMC/
# MOAB Variables
ENV MOAB_BRANCH='Version5.1.0'
ENV MOAB_REPO='https://bitbucket.org/fathomteam/moab/'
ENV MOAB_INSTALL_DIR=$HOME/MOAB/

# DAGMC Variables
ENV DAGMC_BRANCH='develop'
ENV DAGMC_REPO='https://github.com/svalinn/dagmc'
ENV DAGMC_INSTALL_DIR=$HOME/DAGMC/


# MOAB Install
RUN cd $HOME && \
    mkdir MOAB && \
    cd MOAB && \
    git clone -b $MOAB_BRANCH $MOAB_REPO  && \
    mkdir build && cd build && \
    cmake ../moab -DENABLE_HDF5=ON -DENABLE_MPI=off -DENABLE_NETCDF=ON -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=$MOAB_INSTALL_DIR && \
    make -j8 &&  \
    make -j8 install  && \
    cmake ../moab -DBUILD_SHARED_LIBS=OFF && \
    make -j8 install && \
    rm -rf $HOME/MOAB/moab $HOME/MOAB/build


# DAGMC Install
RUN cd $HOME && \
    mkdir DAGMC && cd DAGMC && \
    git clone -b $DAGMC_BRANCH $DAGMC_REPO && \
    mkdir build && \
    cd build && \
    cmake ../dagmc -DBUILD_TALLY=ON -DCMAKE_INSTALL_PREFIX=$DAGMC_INSTALL_DIR -DMOAB_DIR=$MOAB_INSTALL_DIR && \
    make -j8 install && \
    rm -rf $HOME/DAGMC/dagmc $HOME/DAGMC/build

# installs OpenMc from source
RUN cd /opt && \
    git clone https://github.com/openmc-dev/openmc.git && \
    cd openmc && \
    git checkout develop && \
    mkdir build && cd build && \
    cmake -Ddagmc=ON -DDAGMC_ROOT=$DAGMC_INSTALL_DIR -DHDF5_PREFER_PARALLEL=OFF .. && \
    make -j8  && \
    make install  && \
    cd /opt/openmc/  && \
    pip3 install .


# install endf nuclear data

# clone data repository
RUN git clone https://github.com/openmc-dev/data.git

# run script that converts ACE data to hdf5 data
RUN python3 data/convert_nndc71.py --cleanup

ENV OPENMC_CROSS_SECTIONS=/nndc-b7.1-hdf5/cross_sections.xml


ENV LD_LIBRARY_PATH /MOAB/lib:$LD_LIBRARY_PATH

ENV PATH PATH $MOAB_INSTALL_DIR/bin:$PATH
ENV PATH PATH $DAGMC_INSTALL_DIR/bin:$PATH
#these commands should all be found but won't work as they need input files
RUN mbconvert
RUN make_watertight


# make sure that pytest is installed
# we'll need it to run the tests!
RUN pip3 install pytest

# Copy over the source code
COPY minimal_openmc_dagmc_simulations minimal_openmc_dagmc_simulations/

# Copy over the test folder
COPY tests tests/

CMD ["/bin/bash"]
