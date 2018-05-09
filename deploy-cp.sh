#! /bin/bash

function initialize_worker() {
    printf "***************************************************\n\t\tSetting up host \n***************************************************\n"
    # Update packages
    echo ======= Updating packages ========
    sudo apt-get update

    # Export language locale settings
    echo ======= Exporting language locale settings =======
    export LC_ALL=C.UTF-8
    export LANG=C.UTF-8

    # Install pip3
    echo ======= Installing pip3 =======
    sudo apt-get install -y python3-pip
}

function setup_python_venv() {
    printf "***************************************************\n\t\tSetting up Venv \n***************************************************\n"
    # Install virtualenv
    echo ======= Installing virtualenv =======
    pip3 install virtualenv

    # Create virtual environment and activate it
    echo ======== Creating and activating virtual env =======
    virtualenv venv
    source ./venv/bin/activate
}

function clone_app_repository() {
    printf "***************************************************\n\t\tFetching App \n***************************************************\n"
    # Clone and access project directory
    echo ======== Cloning and accessing project directory ========
    if [[ -d ~/yummy-rest ]]; then
        sudo rm -rf ~/yummy-rest
    else
        git clone -b develop https://github.com/indungu/yummy-rest.git ~/yummy-rest
        cd ~/yummy-rest/
    fi
}

function setup_app() {
    printf "***************************************************\n    Installing App dependencies and Env Variables \n***************************************************\n"
    # Install required packages
    echo ======= Installing required packages ========
    pip install -r requirements.txt

    # Export required environment variable
    echo ======= Exporting the necessary environment variables ========
    export DATABASE_URL="postgres://budufkitteymek:095f0029056c313190744c68ca69d19a2e315483bc41e059b40d6d9fdccf2599@ec2-107-22-229-213.compute-1.amazonaws.com:5432/d2r8p5ai580nqq"
    export APP_CONFIG="production"
    export SECRET_KEY="mYd3rTyL!tTl#sEcR3t"
    export FLASK_APP=run.py
}

# Install and configure nginx
function setup_nginx() {
    printf "***************************************************\n\t\tSetting up nginx \n***************************************************\n"
    echo ======= Installing nginx =======
    sudo apt-get install -y nginx

    # Configure nginx routing
    echo ======= Configuring nginx =======
    echo ======= Removing default config =======
    sudo rm -rf /etc/nginx/sites-available/default
    sudo rm -rf /etc/nginx/sites-enabled/default
    echo ======= Replace config file =======
    sudo bash -c 'cat <<EOF> /etc/nginx/sites-available/default
    server {
            listen 80 default_server;
            listen [::]:80 default_server;

            # include snippets/snakeoil.conf;

            root /var/www/html;

            server_name _;

            location / {
                    # reverse proxy and serve the app
                    # running on the localhost:8000
                    proxy_pass http://127.0.0.1:8000/;
                    proxy_set_header HOST $host;
                    proxy_set_header X-Forwarded-Proto $scheme;
                    proxy_set_header X-Real-IP $remote_addr;
                    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            }
    }
    EOF'

    echo ======= Create a symbolic link of the file to sites-enabled =======
    sudo ln -s /etc/nginx/sites-available/default /etc/nginx/sites-enabled/

    # Ensure nginx server is running
    echo ====== Checking nginx server status ========
    sudo systemctl status nginx -q
}

# Serve the web app through gunicorn
function serve_app() {
    printf "***************************************************\n\t\tServing the App \n***************************************************\n"
    gunicorn app:APP
}

######################################################################
########################      RUNTIME         ########################
######################################################################

initialize_worker
setup_python_venv
clone_app_repository
setup_app
setup_nginx
serve_app
exit
