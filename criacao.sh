#!/bin/sh
    # Atualizar o client dentro do projeto layer-serverless

    CLUSTER_IDENTIFIER=lms
    DATABASE_NAME=ead
    CURRENT_PATH=$(pwd)
    CI_JOB_STAGE=dev


    ROOT_FOLDER_LAYERS="/opt/layer-serverless"
    if [ -d ${ROOT_FOLDER_LAYERS} ]
    then
        cd ${ROOT_FOLDER_LAYERS}
        git pull origin master
    else
        cd /opt
        git clone git@gitlab.com.br:group/layer-serverless.git
        cd layer-serverless
    fi

    cd src/layers/MiddyDependenciesPrismaOrm/middy

    if [ ! -d $CLUSTER_IDENTIFIER ]
    then
      mkdir $CLUSTER_IDENTIFIER
      cd $CLUSTER_IDENTIFIER
    else
      cd $CLUSTER_IDENTIFIER
    fi

    if [ ! -d $DATABASE_NAME ]
    then
      mkdir $DATABASE_NAME
      cd $DATABASE_NAME

      npm init -y
      npm i @prisma/client
      npm i @prisma/cli --save-dev

      {
        jq --version
      } || {
        mkdir -p ~/bin && curl -sSL -o ~/bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && chmod +x ~/bin/jq
        export PATH=$PATH:~/bin
        jq --version
      }

      echo $(jq ".scripts += {\"prisma:generate\": \"prisma generate --schema=${CURRENT_PATH}/prisma/schema.prisma\"}" package.json ) > package.json

      MSG_COMMIT="feat(auto deploy) add prisma client in database $CLUSTER_IDENTIFIER"
    else
      cd $DATABASE_NAME
      npm i
      MSG_COMMIT="feat(auto deploy) update prisma client in database $CLUSTER_IDENTIFIER"
    fi

    sed -i "/provider = \"prisma-client-js\"/a output = \"$(pwd)/node_modules/.prisma/client\"" ${CURRENT_PATH}/prisma/schema.prisma
    npm run prisma:generate
    sed -i '/output/d' ${CURRENT_PATH}/prisma/schema.prisma

    git add .
    git commit -m MSG_COMMIT
    git push origin master

    git checkout $CI_JOB_STAGE
    git merge master
    git push origin $CI_JOB_STAGE

