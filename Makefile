# ----------------------------------
#          INSTALL & TEST
# ----------------------------------
install_requirements:
	@pip install -r requirements.txt

check_code:
	@flake8 scripts/* matjari/*.py

black:
	@black scripts/* matjari/*.py

test:
	@coverage run -m pytest tests/*.py
	@coverage report -m --omit="${VIRTUAL_ENV}/lib/python*"

ftest:
	@Write me

clean:
	@rm -f */version.txt
	@rm -f .coverage
	@rm -fr */__pycache__ */*.pyc __pycache__
	@rm -fr build dist
	@rm -fr matjari-*.dist-info
	@rm -fr matjari.egg-info

install:
	@pip install . -U

all: clean install test black check_code


count_lines:
	@find ./ -name '*.py' -exec  wc -l {} \; | sort -n| awk \
        '{printf "%4s %s\n", $$1, $$2}{s+=$$0}END{print s}'
	@echo ''
	@find ./scripts -name '*-*' -exec  wc -l {} \; | sort -n| awk \
		        '{printf "%4s %s\n", $$1, $$2}{s+=$$0}END{print s}'
	@echo ''
	@find ./tests -name '*.py' -exec  wc -l {} \; | sort -n| awk \
        '{printf "%4s %s\n", $$1, $$2}{s+=$$0}END{print s}'
	@echo ''

run_locally:
	@python -m ${PACKAGE_NAME}.${FILENAME}
# ----------------------------------
#      UPLOAD PACKAGE TO PYPI
# ----------------------------------
PYPI_USERNAME=<AUTHOR>
build:
	@python setup.py sdist bdist_wheel

pypi_test:
	@twine upload -r testpypi dist/* -u $(PYPI_USERNAME)

pypi:
	@twine upload dist/* -u $(PYPI_USERNAME)

# ----------------------------------
#      UPLOAD PACKAGE TO GCP
# ----------------------------------
PACKAGE_NAME = matjari
FILENAME = trainer

PYTHON_VERSION=3.8
RUNTIME_VERSION=1.15

BUCKET_TRAINING_FOLDER = trainings

JOB_NAME=matjari_training_pipeline_$(shell date +'%Y%m%d_%H%M%S')

# project id - replace with your GCP project id
PROJECT_ID=wagon-bootcamp-352309

# bucket name - replace with your GCP bucket name
BUCKET_NAME=wagon-data-839-melliani

# choose your region
#REGION=europe-west1

set_project:
	@gcloud config set project ${PROJECT_ID}

create_bucket:
	@gsutil mb -l europe-west1 -p ${PROJECT_ID} gs://${BUCKET_NAME}

# path to the file to upload to GCP (the path to the file should be absolute or should match the directory where the make command is ran)
# replace with your local path to the `train_1k.csv` and make sure to put the path between quotes
LOCAL_PATH="/Users/Safaemichelot/code/aidakd/matjari/raw_data/matjari-dataset-cleaned.csv"

# bucket directory in which to store the uploaded file (`data` is an arbitrary name that we choose to use)
BUCKET_FOLDER=data

# name for the uploaded file inside of the bucket (we choose not to rename the file that we upload)
BUCKET_FILE_NAME=$(shell basename ${LOCAL_PATH})

upload_data:
	@gsutil cp ${LOCAL_PATH} gs://${BUCKET_NAME}/${BUCKET_FOLDER}/${BUCKET_FILE_NAME}

gcp_submit_training:
	gcloud ai-platform jobs submit training ${JOB_NAME}
		--job-dir gs://${BUCKET_NAME}/${BUCKET_TRAINING_FOLDER}/  \
  	--package-path ${PACKAGE_NAME} \
  	--module-name ${PACKAGE_NAME}.${FILENAME} \
  	--python-version=${PYTHON_VERSION} \
  	--runtime-version=${RUNTIME_VERSION} \
		--region europe-west1 \
  	--stream-logs
