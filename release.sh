#!/bin/bash

DEFAULT_BRANCH=$(git remote show origin | grep 'HEAD branch' | awk '{print $NF}')
NEW_VERSION_NUMBER=""

illegal_option() {
    echo "$(basename "$0"): illegal option: $OPTARG" >&2
    echo "usage: $(basename "$0") [-p for patch | -m for minor | -M for major]"
    exit 1
}

create_tag()
{
  echo "🔍 Searching latest versions..."

  git pull > /dev/null 2>&1

  VERSION=$(git tag -l --sort -version:refname | grep v -m 1)

  if [ -z "$VERSION" ]
  then
      echo "😎 Version v0.1.0 will be created"
      NEW_VERSION_NUMBER="v0.1.0"
  else
    echo "😎 Latest version is $VERSION"
    VERSION_NUMBER="${VERSION//v/}"
    IFS='.' read -r VNUM1 VNUM2 VNUM3 <<< "$VERSION_NUMBER"

    case "$1" in
      major)
        VNUM1=$((VNUM1+1)); VNUM2=0; VNUM3=0;;
      minor)
        VNUM2=$((VNUM2+1)); VNUM3=0;;
      patch)
        VNUM3=$((VNUM3+1));;
    esac

    NEW_VERSION_NUMBER="v$VNUM1.$VNUM2.$VNUM3"
  fi

  echo "😎 Creating a new version $NEW_VERSION_NUMBER"

  git tag "v$NEW_VERSION_NUMBER" > /dev/null 2>&1
  git push --tags > /dev/null 2>&1

  REPOSITORY_URL=$(git config --get remote.origin.url)
  REPOSITORY_NAME=$(echo "$REPOSITORY_URL" | sed -E 's/.*\/(.*)\.git/\1/')

  echo "🚀 https://app.circleci.com/pipelines/github/archmix/$REPOSITORY_NAME"
}

validate_branch()
{
  git_version=$(git --version | awk '{print $3}' | sed 's/\([0-9]*\.[0-9]*\)\.[0-9]*/\1/')
  git_version=$(echo "$git_version" | tr -d '.')
  if (( git_version < 222 )); then
    branch=$(git rev-parse --abbrev-ref HEAD)
  else
    branch=$(git branch --show-current)
  fi

  if [[ "$branch" != "$DEFAULT_BRANCH" ]]; then
    echo "😖 Release tags can only be created from $DEFAULT_BRANCH branch. Current branch: $branch"
    exit 1
  fi
}

# --- MAIN ---
VERSION_INCREMENT=""

while getopts 'pmM' OPTION; do
  case "$OPTION" in
    p) VERSION_INCREMENT="patch" ;;
    m) VERSION_INCREMENT="minor" ;;
    M) VERSION_INCREMENT="major" ;;
    ?) illegal_option ;;
  esac
done

# No option passed
if (( OPTIND == 1 )); then
  illegal_option
fi

validate_branch
echo "😎 Creating tag for version type $VERSION_INCREMENT"
create_tag "$VERSION_INCREMENT"
