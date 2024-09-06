#!/bin/bash

# Define the project paths
CRM="tmart/customers"
INVENTORY="tmart/inventory"
SHIPMENT="tmart/shipment"
PORTAL="tmart/tmart-portal"
MI_BOOKPARK="tomsbooks/bookpark"

export DOCKER_BUILDKIT=0

# Function to build a Ballerina project
build_project() {
    local project_path=$1
    
    echo "Building Ballerina project in $project_path"
    
    # Navigate to the project directory
    cd "$project_path" || exit
    
    # Run the Ballerina build command
    bal build --cloud=k8s
    
    # Check if the build was successful
    if [ $? -eq 0 ]; then
        echo "Build successful for project: $project_path"
    else
        echo "Build failed for project: $project_path"
        exit 1
    fi
    
    # Navigate back to the initial directory
    cd - > /dev/null
}

# Function to build the Maven project
build_maven_project() {
    local project_path=$1
    
    echo "Building MI project in $project_path"
    
    # Navigate to the Maven project directory
    cd "$project_path" || exit
    
    # Run the Maven build command
    mvn clean package -Pdocker
    
    # Check if the build was successful
    if [ $? -eq 0 ]; then
        echo "Maven build successful for project: $project_path"
    else
        echo "Maven build failed for project: $project_path"
        exit 1
    fi
    
    # Navigate back to the initial directory
    cd - > /dev/null
}

# Build the Ballerina projects
build_project "$CRM"
build_project "$INVENTORY"
build_project "$SHIPMENT"
build_project "$PORTAL"

# Build the MI project
build_maven_project "$MI_BOOKPARK"

cd "deployment" || exit
helm upgrade --install demo integration-demo

echo "All projects built and installed successfully."
