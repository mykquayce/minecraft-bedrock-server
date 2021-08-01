#! /bin/bash


# get the webpage
html=$(curl --silent --url https://www.minecraft.net/en-us/download/server/bedrock)


# scrape html
uri=$(echo -n $html | \
	grep --ignore-case \
		--only-matching \
		--extended-regexp "https:\/\/minecraft\.azureedge\.net\/bin-linux\/bedrock-server-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\.zip")


if [ -z "$uri" ]; then
	echo "failed to scrape link from webpage"
	exit 1
fi


echo uri: $uri


# scrape filename
file_name=$(echo -n $uri | grep --ignore-case --only-matching --extended-regexp "bedrock-server-[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+.zip")


echo file_name: $file_name


# scrape version
version=$(echo -n $file_name | grep --only-matching --extended-regexp "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+")


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
tag1=$image:$(echo -n $version | grep --extended-regexp --only-matching "^[0-9]+")
tag2=$image:$(echo -n $version | grep --extended-regexp --only-matching "^[0-9]+\.[0-9]+")
tag3=$image:$(echo -n $version | grep --extended-regexp --only-matching "^[0-9]+\.[0-9]+\.[0-9]+")
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
