#! /bin/bash


# get the webpage
html=$(curl --silent --url https://www.minecraft.net/en-us/download/server/bedrock)


# scrape html
uri=$(echo -n $html | \
	grep --ignore-case \
		--only-matching \
		--perl-regex "https:\/\/minecraft\.azureedge\.net\/bin-linux\/bedrock-server-\d+\.\d+\.\d+\.\d+\.zip")


if [ -z "$uri" ]; then
	echo "failed to scrape link from webpage"
	exit 1
fi


echo uri: $uri


# scrape filename
file_name=$(echo -n $uri | grep --ignore-case --only-matching --perl-regex "bedrock-server-\d+\.\d+\.\d+\.\d+.zip")


echo file_name: $file_name


# scrape version
version=$(echo -n $file_name | grep --only-matching --perl-regex "\d+\.\d+\.\d+\.\d+")


echo version: $version


# edit Dockerfile with the new version
sed --in-place --regexp-extended --expression="s/^ARG version=.+$/ARG version=$version/" ./Dockerfile


# commit (any) changes
git commit --message "update to version $version" ./Dockerfile &>/dev/null


# if there was error, i.e, nothing to commit
if [ $? -eq 1 ]; then
	echo everything up to date
	exit 0
fi

#tag
git tag --annotate "v$version" --message "release added"


# push to origin
git push && git push --tags


# docker : pull referenced images
cat ./Dockerfile | \
	egrep --only-matching "FROM \w+:\w+" | \
	uniq --ignore-case | \
	awk '{system("docker pull " $2)}'


# docker : make the tags
image=eassbhhtgu/minecraft-bedrock-server
tag1=$image:$(echo -n $version | grep --perl-regex --only-matching "^\d+")
tag2=$image:$(echo -n $version | grep --perl-regex --only-matching "^\d+\.\d+")
tag3=$image:$(echo -n $version | grep --perl-regex --only-matching "^\d+\.\d+\.\d+")
tag4=$image:$version
tag5=$image:latest


# docker : build
docker build --tag $tag1 --tag $tag2 --tag $tag3 --tag $tag4 --tag $tag5 .


# docker : push
docker push $tag1
docker push $tag2
docker push $tag3
docker push $tag4
docker push $tag5
