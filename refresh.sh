#! /bin/bash


# pull the Docker images referenced in ./Dockerfile
cat ./Dockerfile | \
	grep --ignore-case --only-matching --perl-regex '^from \w+:\w+' | \
	uniq --ignore-case | \
	awk '{system("docker pull " $2)}'


# scrape the version numbers from the Wiki
versions=$(curl --silent --url https://minecraft.fandom.com/wiki/Bedrock_Dedicated_Server | \
	grep --ignore-case --only-matching --perl-regex '<a href=".+?" title=".+?">\d+\.\d+.\d+.\d+</a>' | \
	grep --ignore-case --only-matching --perl-regex '\d+\.\d+\.\d+\.\d+')


# foreach version
for version in $versions
do
	echo $version
	sed --in-place --regexp-extended --expression="s/^ARG version=.+$/ARG version=$version/" ./Dockerfile


	# docker : make the tags
	image=eassbhhtgu/minecraft-bedrock-server
	tag1=$image:$(echo -n $version | grep --only-matching --perl-regex "^\d+")
	tag2=$image:$(echo -n $version | grep --only-matching --perl-regex "^\d+\.\d+")
	tag3=$image:$(echo -n $version | grep --only-matching --perl-regex "^\d+\.\d+\.\d+")
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
done
