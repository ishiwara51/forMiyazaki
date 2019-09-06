# Use an official Python runtime as a parent image
FROM centos:7

RUN sudo yum -y install curl-devel expat-devel gettext-devel openssl-devel zlib-devel;\
    sudo yum -y install git;\
    sudo yum -y install gcc zlib-devel bzip2 bzip2-devel readline-devel sqlite sqlite-devel openssl-devel tk-devel libffi-devel;\
    sudo yum -y install gcc gcc-c++ kernel-devel;\　
    sudo yum -y install lzma; sudo yum -y install libsndfile;\
    sudo yum -y install zip unzip
    #git clone https://github.com/pyenv/pyenv.git ~/.pyenv;\
    echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bash_profile;\
    echo 'export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bash_profile;\
    echo -e 'if command -v pyenv 1>/dev/null 2>&1; then\n  eval "$(pyenv init -)"\nfi' >> ~/.bash_profile;\
    exec "$SHELL"; source ~/.bash_profile;\
    #pyenv install 3.7.2; pyenv global 3.7.2;\
    #pip install --upgrade pip setuptools;\
    #pip install Flask; pip install magenta;\
    git clone https://github.com/ishiwara51/forMiyazaki ~/forMiyazaki
    
    
