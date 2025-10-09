#!/bin/bash

# Define the source folders (relative to push_image.sh)
SOURCE_FOLDER_LIB="../../../shared/lib"
SOURCE_FOLDER_ENTITIES="../../../shared/entities"

# Function to load environment variables from .env file
load_env_file() {
  if [ -f "../.env" ]; then
    echo "📋 Found .env file, loading environment variables..."
    export $(grep -v '^#' ../.env | grep -v '^$' | xargs)
    echo "✅ Environment variables loaded from .env file"
  elif [ -f "../../../.env" ]; then
    echo "📋 Found root .env file, loading environment variables..."
    export $(grep -v '^#' ../../../.env | grep -v '^$' | xargs)
    echo "✅ Environment variables loaded from root .env file"
  else
    echo "⚠️  No .env file found in service or root directory"
  fi
}

# Function to check and load required environment variables
check_and_load_env() {
  # Check if AWS_REGION and AWS_ACCOUNT_ID are already set
  if [[ -z "$AWS_REGION" || -z "$AWS_ACCOUNT_ID" ]]; then
    echo "🔍 AWS environment variables not found in terminal, checking .env file..."
    load_env_file
  fi

  # Verify required environment variables are now set
  if [[ -z "$AWS_REGION" || -z "$AWS_ACCOUNT_ID" ]]; then
    echo "❌ ERROR: AWS_REGION and AWS_ACCOUNT_ID must be set."
    echo "Please either:"
    echo "   1. Export them as environment variables:"
    echo "      export AWS_REGION=your-region"
    echo "      export AWS_ACCOUNT_ID=your-account-id"
    echo "   2. Or create a .env file with:"
    echo "      AWS_REGION=your-region"
    echo "      AWS_ACCOUNT_ID=your-account-id"
    exit 1
  fi

  echo "✅ AWS environment variables loaded:"
  echo "   AWS_REGION: $AWS_REGION"
  echo "   AWS_ACCOUNT_ID: $AWS_ACCOUNT_ID"
}

# Copying Lib and Entities folders
copy_lib_and_entities() {
  local service_dir=$1
  DESTINATION_NAME="$service_dir/src"

  # Check if the source folders exist
  if [ ! -d "$SOURCE_FOLDER_LIB" ]; then
    echo "❌ Source folder '$SOURCE_FOLDER_LIB' does not exist. Exiting."
    exit 1
  fi

  if [ ! -d "$SOURCE_FOLDER_ENTITIES" ]; then
    echo "❌ Source folder '$SOURCE_FOLDER_ENTITIES' does not exist. Exiting."
    exit 1
  fi

  # Ensure destination directory exists
  mkdir -p "$DESTINATION_NAME"

  # Copy the source folders into the service directory
  echo "📁 Copying source folders..."
  echo "Copying from: $SOURCE_FOLDER_LIB -> $DESTINATION_NAME"
  cp -r "$SOURCE_FOLDER_LIB" "$DESTINATION_NAME"
  echo "Copying from: $SOURCE_FOLDER_ENTITIES -> $DESTINATION_NAME"
  cp -r "$SOURCE_FOLDER_ENTITIES" "$DESTINATION_NAME"
}

# Function to check the success of the last command
check_status() {
  if [ $? -ne 0 ]; then
    echo "❌ ERROR: $1 failed."
    exit 1
  fi
}

# Check and load environment variables from .env if needed
check_and_load_env

# Configuration
REPO_NAME="verification-service"
IMAGE_TAG="latest"
ECR_URL="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

echo "🚀 Starting image build and push for verification service"
echo "📋 Configuration:"
echo "   Repository: $REPO_NAME"
echo "   Image Tag: $IMAGE_TAG"
echo "   ECR URL: $ECR_URL"
echo "   AWS Region: $AWS_REGION"
echo "   AWS Account: $AWS_ACCOUNT_ID"
echo ""

# === Copy shared folders into service ===
copy_lib_and_entities ".."

# Change to service directory
cd ..

# Authenticate with AWS ECR
echo "🔑 Logging in to Amazon ECR..."
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$ECR_URL"
check_status "ECR Login"

# Build Docker image
echo "🐳 Building Docker Image..."
docker build -t "$REPO_NAME" .
check_status "Docker Build"

# Tag the image
echo "🏷️ Tagging Docker Image..."
docker tag "$REPO_NAME:latest" "$ECR_URL/$REPO_NAME:$IMAGE_TAG"
check_status "Docker Tagging"

# Push image to ECR
echo "🚀 Pushing Docker Image to ECR..."
docker push "$ECR_URL/$REPO_NAME:$IMAGE_TAG"
check_status "Docker Push"

echo ""
echo "🎉 Docker image build and push completed successfully!"
echo "📝 Summary:"
echo "   ✅ Image built and pushed to ECR: $ECR_URL/$REPO_NAME:$IMAGE_TAG"
echo ""
echo "💡 To deploy the service, run: ./scripts/deploy_ecs.sh"