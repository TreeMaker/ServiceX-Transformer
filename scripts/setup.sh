#!/bin/bash -e

CMSSWVER=CMSSW_10_2_21
DIR="${HOME}"
OFILE="testfile.root"
OPATH="TreeMaker/Production/test/"
URL=""

usage(){
    EXIT=$1

    echo "setup.sh [options]"
    echo ""
    echo "-c [version]        use specified CMSSW version (default = ${CMSSWVER})"
    echo "-d [dir]            project installation area for the CMSSW directory (default = ${DIR})"
    echo "-f [filename]       the output filename for the downloaded file (default = ${OFILE})"
    echo "-p [path]           the output path for the downloaded file (default = ${OPATH})"
    echo "-u [url]            a url to download (default = ${URL})"
    echo "-h                  display this message and exit"

    exit $EXIT
}

# process options
while getopts "c:d:f:p:u:h" opt; do
    case "$opt" in
    c) CMSSWVER=$OPTARG
    ;;
    d) DIR=$OPTARG
    ;;
    f) OFILE=$OPTARG
    ;;
    p) OPATH=$OPTARG
    ;;
    u) URL=$OPTARG
    ;;
    h) usage 0
    ;;
    esac
done

# Add these lines to the .bashrc and .zshrc files
echo "Adding some lines to the login files ... "
lines="# Turn this on so that stdout isn't buffered - otherwise logs in kubectl don't\n\
#   show up until much later!\n\
export PYTHONUNBUFFERED=1\n\
export X509_USER_PROXY=/etc/grid-security/x509up\n\n\
# Add this line to add the '.local/bin' folder to the PATH environment variable\n\
export PATH=\""'${PATH}:${HOME}'"/.local/bin\"\n"
echo -e ${lines} >> ${HOME}/.bashrc
echo -e ${lines} >> ${HOME}/.zshrc

# Install missing python packages into the images base python version
if [[ -x "$(command -v pip)" ]]; then
	echo "Installing packages into the system python via 'pip' ... "
	python2 -m pip install --user --no-cache-dir --upgrade pip
	python2 -m pip install --user --no-cache-dir -r ${HOME}/ServiceX-Transformer/data/requirements.txt
else
	echo "Unable to install packages into the system python because 'pip' is not installed!"
fi

# Make the /servicex directory and copy some files into it
echo "Setting up the /servicex directory ... "
if [[ ! -d "/servicex" ]]; then
	if [[ -x "$(command -v sudo)" ]]; then
		sudo mkdir /servicex/
		sudo chown -R cmsusr:cmsusr /servicex
	else
		echo "Unable to make the '/servicex' folder!"
		exit 1
	fi
fi
cp ${HOME}/.bashrc /servicex/.bashrc
cp ${HOME}/.zshrc /servicex/.zshrc
cp ${HOME}/ServiceX-Transformer/scripts/proxy-exporter.sh /servicex/
cp ${HOME}/ServiceX-Transformer/python/validate_requests.py /servicex/
cp ${HOME}/ServiceX-Transformer/python/transformer.py /servicex/

# Source the cmsset if in a standalone CMSSW image
echo "Sourcing the cmsset ... "
if [[ -f /opt/cms/cmsset_default.sh ]]; then
	source /opt/cms/cmsset_default.sh
elif [[ -f /cvmfs/cms.cern.ch/cmsset_default.sh ]]; then
    source /cvmfs/cms.cern.ch/cmsset_default.sh
fi

# Move to the CMSSW directory and initialize the CMSSW environment
pwd
ls -alh ./
cd ${DIR}/${CMSSWVER}/src/
pwd
ls -alh ./
echo "Setting the CMSSW environment ..."
eval `scramv1 runtime -sh`

# Install missing python packages
echo "Installing packages into the CMSSW python via 'pip' ... "
python -m pip install --user --no-cache-dir -r ${HOME}/ServiceX-Transformer/data/requirements.txt

# Download CMS Open Data test file
if [[ -n "$URL" ]]; then
    DESTINATION="${CMSSW_BASE}/src/${OPATH}/${OFILE}"
    echo -e "Downloading a file ...\n\tFrom: ${URL}\n\tDestination: ${DESTINATION}"
    wget --progress=dot:giga ${URL} -O ${DESTINATION}
fi

# Return to the ${HOME} directory
echo "Returning to ${HOME} ... "
cd ${HOME}
