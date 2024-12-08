FILES_DIR="../../files"
PUPPET_RELEASE="puppet8-release-noble.deb"

install_puppet() {
    if [ -f "/usr/bin/puppet" ]; then
        echo "Puppet is already installed."
        return 0
    fi

    cd $FILES_DIR
    wget https://apt.puppet.com/${PUPPET_RELEASE}
    sudo dpkg -i ${PUPPET_RELEASE}
    sudo apt-get update
    sudo apt-get install puppet-agent
    cd /usr/bin
    sudo ln -s /opt/puppetlabs/bin/puppet puppet
    cd -> /dev/null
    echo "Puppet installed successfully."
}

if [ $# -eq 0 ]; then
    echo "Usage:"
    echo "sh deploy.sh download: Download the required artifacts. Artifacts will be downloaded to the 'observability-resources/files' directory."
    echo "sh deploy.sh prepare: Prepare the puppet artifacts for deployment."
    echo "sh deploy.sh local: Deploy the observability solution locally."
    exit 1
fi

if [ "$1" == "download" ]; then
    cd ../../files
    wget https://download.java.net/java/GA/jdk17.0.2/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/openjdk-17.0.2_linux-x64_bin.tar.gz
    wget https://artifacts.opensearch.org/releases/bundle/opensearch/2.15.0/opensearch-2.15.0-linux-x64.tar.gz
    wget https://artifacts.opensearch.org/releases/bundle/opensearch-dashboards/2.15.0/opensearch-dashboards-2.15.0-linux-x64.tar.gz
    cd -> /dev/null
    echo "Observability artifacts downloaded successfully."
fi

if [ "$1" == "prepare" ]; then

    # Check if FILES_DIR exists
    if [ ! -d "$FILES_DIR" ]; then
        echo "Error: Directory $FILES_DIR does not exist."
        exit 1
    fi

    if [ -f "$FILES_DIR"/openjdk-17*.tar.gz ]; then
        cp "$FILES_DIR"/openjdk-17*.tar.gz puppet/code/environments/production/modules/o11y_common/files/
    fi
    
    cp "$FILES_DIR"/opensearch-2.*.tar.gz puppet/code/environments/production/modules/opensearch/files/
    cp "$FILES_DIR"/opensearch-dashboards-2.*.tar.gz puppet/code/environments/production/modules/opensearch_dashboards/files/

    echo "Observability puppet artifacts are ready for deployment."
fi

if [ "$1" == "local" ]; then
    install_puppet
    
    cd puppet/code

    sudo puppet module install puppetlabs-apt --modulepath /opt/puppetlabs/puppet/modules/
    sudo puppet module install puppetlabs-docker --modulepath /opt/puppetlabs/puppet/modules/

    export FACTER_profile=opensearch
    puppet apply --environmentpath=environments --environment=production environments/production/manifests/site.pp

    export FACTER_profile=opensearch_dashboards
    puppet apply --environmentpath=environments --environment=production environments/production/manifests/site.pp

    export FACTER_profile=fluentbit
    puppet apply --environmentpath=environments --environment=production environments/production/manifests/site.pp

    export FACTER_profile=data_prepper
    puppet apply --environmentpath=environments --environment=production environments/production/manifests/site.pp

    echo "Observability solution deployed successfully."
fi