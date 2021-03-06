#!/bin/bash
# This script generates a conda file for python, pyspark, gpu or
# all environments.
# For generating a conda file for running only python code:
# $ sh generate_conda_file.sh
# For generating a conda file for running python gpu:
# $ sh generate_conda_file.sh --gpu
# For generating a conda file for running pyspark:
# $ sh generate_conda_file.sh --pyspark
# For generating a conda file for running python gpu and pyspark:
# $ sh generate_conda_file.sh --gpu --pyspark
# For generating a conda file for running python gpu and pyspark with a particular version:
# $ sh generate_conda_file.sh --gpu --pyspark-version 2.4.0
#

# first check if conda is installed
CONDA_BINARY=$(which conda)
if [ ! -x "$CONDA_BINARY" ] ; then
	echo "No conda found!! Please see the SETUP.md file for installation prerequisites."
	exit 1
fi


# File which contains conda configuration virtual environment name
CONDA_FILE="conda_bare.yaml"

# default CPU-only no-pySpark versions of conda packages.
tensorflow="tensorflow"
gpu="#"
pyspark="#"

# flags to detect if both CPU and GPU are specified
gpu_flag=false
pyspark_flag=false

# default version of pyspark if it is installed
pyspark_version=2.3.1

while [ ! $# -eq 0 ]
do
	case "$1" in
		--help)
			echo "Please specify --gpu to install with GPU-support and"
			echo "--pyspark to install with pySpark support"
			echo "--pyspark-version X.Y.Z to install version X.Y.Z of pySpark (default: $pyspark_version)"
			exit
			;;
		--gpu)
			gpu=""
			tensorflow="tensorflow-gpu"
			CONDA_FILE="conda_gpu.yaml"
			gpu_flag=true
			;;
		--pyspark)
			pyspark=""
			CONDA_FILE="conda_pyspark.yaml"
			pyspark_flag=true
			;;			
		--pyspark-version)
			pyspark=""
			CONDA_FILE="conda_pyspark.yaml"
			pyspark_flag=true
			pyspark_version=$2
			## update to use with sh
			good_version=$(echo $pyspark_version | awk '$0 ~ "^[0-9]+([.][0-9]+){2}$"{print 1}')
			if ! [ "$good_version" = "1" ]; then
				echo "Inappropriate version of pyspark passed:" $pyspark_version
				echo "Version must be of format X.Y.Z"
				exit 1
			fi
			shift
			;;			
		*)
			echo $"Usage: $0 invalid argument $1 please run with --help for more information."
			exit 1
	esac
	shift
done

if [ "$pyspark_flag" = true ] && [ "$gpu_flag" = true ]; then
	CONDA_FILE="conda_full.yaml"
fi

# Write conda file with libraries
/bin/cat <<EOM >${CONDA_FILE}
# To create the conda environment:
# $ conda env create -n my_env_name -f conda.yml
#
# To update the conda environment:
# $ conda env update -n my_env_name -f conda.yaml
#
# To register the conda environment in Jupyter:
# $ python -m ipykernel install --user --name my_env_name --display-name "Python (my_env_name)"
#

channels:
- conda-forge
- pytorch
- fastai
- defaults
dependencies:
- python==3.6.8
- numpy>=1.13.3
- dask>=0.17.1
${pyspark}- pyspark==${pyspark_version}
- pymongo>=3.6.1
- ipykernel>=4.6.1
- ${tensorflow}==1.12.0
- scikit-surprise>=1.0.6
- scikit-learn==0.19.1
- jupyter>=1.0.0
- fastparquet>=0.1.6
${pyspark}- pyarrow>=0.8.0
- fastai>=1.0.40
- pip:
  - pandas>=0.23.4
  - hyperopt==0.1.1
  - idna==2.7
  - scipy>=1.0.0
  - azure-storage>=0.36.0
  - matplotlib>=2.2.2
  - seaborn>=0.8.1
  - pytest>=3.6.4
  - papermill>=0.15.0
  - black>=18.6b4
  - memory-profiler>=0.54.0
  - azureml-sdk[notebooks,contrib]==1.0.10
${gpu}  - numba>=0.38.1 
  - gitpython>=2.1.8
  - pydocumentdb>=2.3.3
  - nvidia-ml-py3>=7.352.0
  - dataclasses>=0.6
EOM

echo "Conda file generated: " $CONDA_FILE

