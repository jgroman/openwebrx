#!/bin/bash
set -euxo pipefail
export MAKEFLAGS="-j4"

function cmakebuild() {
  cd $1
  if [[ ! -z "${2:-}" ]]; then
    git checkout $2
  fi
  mkdir build
  cd build
  cmake ${CMAKE_ARGS:-} ..
  make
  make install
  cd ../..
  rm -rf $1
}

cd /tmp

STATIC_PACKAGES="sox libfftw3-bin python3 python3-setuptools netcat-openbsd libsndfile1 liblapack3 libusb-1.0-0 libqt5serialport5 libqt5multimedia5-plugins libqt5widgets5 libqt5sql5-sqlite libqt5core5a libqt5multimedia5 libqt5network5 libqt5printsupport5 libqt5serialport5 libqt5sql5 libqt5widgets5 libreadline7 libgfortran4 libgomp1 libasound2 libudev1 libhamlib2 ca-certificates"
BUILD_PACKAGES="wget git libsndfile1-dev libfftw3-dev cmake make gcc g++ liblapack-dev autoconf automake libtool texinfo gfortran libusb-1.0-0-dev qtbase5-dev qtmultimedia5-dev qttools5-dev libqt5serialport5-dev qttools5-dev-tools asciidoctor asciidoc libasound2-dev pkg-config libudev-dev libhamlib-dev patch xsltproc"

apt-get update
apt-get -y install --no-install-recommends $STATIC_PACKAGES $BUILD_PACKAGES

git clone https://github.com/jketterl/js8py.git
pushd js8py
git checkout 888e62be375316882ad2b2ac8e396c3bf857b6fc
python3 setup.py install
popd
rm -rf js8py

git clone https://git.code.sf.net/p/itpp/git itpp
cmakebuild itpp bb5c7e95f40e8fdb5c3f3d01a84bcbaf76f3676d

git clone https://github.com/jketterl/csdr.git
cd csdr
git checkout 69c4d74a5b8207b0edf4a36a5a0795fbee39281f
autoreconf -i
./configure
make
make install
cd ..
rm -rf csdr

git clone https://github.com/szechyjs/mbelib.git
cmakebuild mbelib 9a04ed5c78176a9965f3d43f7aa1b1f5330e771f

git clone https://github.com/jketterl/digiham.git
cmakebuild digiham 95206501be89b38d0267bf6c29a6898e7c65656f

git clone https://github.com/f4exb/dsd.git
cmakebuild dsd f6939f9edbbc6f66261833616391a4e59cb2b3d7

JS8CALL_VERSION=2.1.1
JS8CALL_DIR=js8call-${JS8CALL_VERSION}
JS8CALL_TGZ=${JS8CALL_DIR}.tgz
wget http://files.js8call.com/${JS8CALL_VERSION}/${JS8CALL_TGZ}
tar xfz ${JS8CALL_TGZ}
# patch allows us to build against the packaged hamlib
patch -Np1 -d ${JS8CALL_DIR} < /js8call-hamlib.patch
rm /js8call-hamlib.patch
CMAKE_ARGS="-D CMAKE_CXX_FLAGS=-DJS8_USE_LEGACY_HAMLIB" cmakebuild ${JS8CALL_DIR}
rm ${JS8CALL_TGZ}

WSJT_DIR=wsjtx-2.1.2
WSJT_TGZ=${WSJT_DIR}.tgz
wget http://physics.princeton.edu/pulsar/k1jt/${WSJT_TGZ}
tar xfz ${WSJT_TGZ}
cmakebuild ${WSJT_DIR}
rm ${WSJT_TGZ}

git clone --depth 1 -b 1.5 https://github.com/wb2osz/direwolf.git
cd direwolf
make
make install
cd ..
rm -rf direwolf

git clone https://github.com/hessu/aprs-symbols /opt/aprs-symbols
pushd /opt/aprs-symbols
git checkout 5c2abe2658ee4d2563f3c73b90c6f59124839802
popd

apt-get -y purge --autoremove $BUILD_PACKAGES
apt-get clean
rm -rf /var/lib/apt/lists/*
