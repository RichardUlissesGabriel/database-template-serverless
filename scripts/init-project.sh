#!/bin/bash
REPOSITORY_NAME=${PWD##*/}
GIT_REMOTE=$(git remote -v)

if [[ "$GIT_REMOTE" != *"$REPOSITORY_NAME"* ]]
then

  echo "============================================================================================================="
  echo "  Initializing the project $REPOSITORY_NAME"
  echo "============================================================================================================="

  # this token is configured inside of richar.gabriel gitlab account
  USER_ID=15
  TOKEN="pj_y-zx8k4CaxUPhgW4c"

  # erase this project-template-serverless
  echo "============================================================================================================="
  echo "  Erasing old reference to project-template-serverless project!!!!"
  echo "============================================================================================================="
  rm -rf .git
  rm -rf CHANGELOG.md

  echo "============================================================================================================="
  echo "  Creating the new repository $REPOSITORY_NAME this name is equal the folder's name"
  echo "============================================================================================================="
  # creating the repo
  NEW_REPO=$(curl -H "Content-Type:application/json" https://gitlab.com.br/api/v4/projects?private_token=$TOKEN -d "{ \"name\": \"$REPOSITORY_NAME\", \"namespace_id\": 5 }")
  NEW_REPO_ID=$(node ./scripts/get-id.js "$NEW_REPO" "id")
  curl --request POST --header "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com.br/api/v4/projects/$NEW_REPO_ID/repository/branches?branch=master&ref=master"
  curl --request POST --header "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com.br/api/v4/projects/$NEW_REPO_ID/variables" --form "key=AWS_ACCESS_KEY_ID" --form "value=XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  curl --request POST --header "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com.br/api/v4/projects/$NEW_REPO_ID/variables" --form "key=AWS_ACCESS_KEY_ID_DEV" --form "value=XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  curl --request POST --header "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com.br/api/v4/projects/$NEW_REPO_ID/variables" --form "key=AWS_SECRET_ACCESS_KEY" --form "value=XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
  curl --request POST --header "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com.br/api/v4/projects/$NEW_REPO_ID/variables" --form "key=AWS_SECRET_ACCESS_KEY_DEV" --form "value=XXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

  echo ""
  echo "============================================================================================================="
  echo "  Adding all files inside the new repository"
  echo "============================================================================================================="
  # change package name
  sed -i "/\"name\":/c\\\  \"name\": \"$REPOSITORY_NAME\"," package.json
  sed -i "/\"version\":/c\\\  \"version\": \"1.0.0\"," package.json

  # start a new repository
  git init
  git remote add origin git@gitlab.com.br:desenvolvimento/$REPOSITORY_NAME.git
  git checkout -b initial

  git add .
  git commit -m "feat: Add initial configuration of project" -m "this commit is automated from script init-project"

  echo "============================================================================================================="
  echo "  Sending everthing to the origin master"
  echo "============================================================================================================="
  git pull origin master --allow-unrelated-histories --rebase
  # sending all configuration to the origin
  git push -u origin initial

  # make merge request
  MERGE_REQUEST=$(curl -H "Content-Type:application/json" https://gitlab.com.br/api/v4/projects/$NEW_REPO_ID/merge_requests?private_token=$TOKEN -d "{\"id\": \"$USER_ID\", \"source_branch\":\"initial\", \"target_branch\":\"master\", \"title\":\"start-project\", \"remove_source_branch\":true }")
  MERGE_REQUEST_ID=$(node ./scripts/get-id.js "$MERGE_REQUEST" "iid")

  # execute merge request
  curl --request PUT --header "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com.br/api/v4/projects/$NEW_REPO_ID/merge_requests/$MERGE_REQUEST_ID/merge"

  git checkout master
  git pull origin master

  git checkout -b dev

  # let's create infrastructure
  npm run create-infrastructure

  rm -rf node_modules

  git add .
  git commit -m "feat: Add initial prisma client configuration" -m "this commit is automated from script init-project"
  git push origin dev

  # make merge request
  MERGE_REQUEST=$(curl -H "Content-Type:application/json" https://gitlab.com.br/api/v4/projects/$NEW_REPO_ID/merge_requests?private_token=$TOKEN -d "{\"id\": \"$USER_ID\", \"source_branch\":\"dev\", \"target_branch\":\"master\", \"title\":\"configure-prisma\", \"remove_source_branch\":false }")
  MERGE_REQUEST_ID=$(node ./scripts/get-id.js "$MERGE_REQUEST" "iid")

  # execute merge request
  curl --request PUT --header "PRIVATE-TOKEN: $TOKEN" "https://gitlab.com.br/api/v4/projects/$NEW_REPO_ID/merge_requests/$MERGE_REQUEST_ID/merge"

  # create initial tag
  git tag 1.0.0
  git push --tags

  # let's add some restriction to work with this project, we need to use all of features
  # but we need git in version 2.13.x or greater, let's put the restriction to install dependencies
  npm config set unsafe-perm true

  # let's verify the version of git from user
  npm run update-git-version

else
  echo "============================================================================================================="
  echo "  this project has already initialized!!!"
  echo "============================================================================================================="
fi
