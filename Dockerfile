FROM ubuntu:latest AS unzip
ARG version=1.21.44.01
RUN apt-get update && apt-get install --assume-yes curl unzip
RUN curl --output './bedrock-server.zip' \
	--url "https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-$version.zip" \
	--user-agent 'Mozilla/5.0 (iPad; U; CPU OS 3_2_1 like Mac OS X; en-us) AppleWebKit/531.21.10 (KHTML, like Gecko) Mobile/7B405'
RUN unzip ./bedrock-server.zip -d ./bedrock-server -x *.debug

FROM ubuntu:latest AS run
EXPOSE 19132/tcp 19133/tcp
RUN apt-get update && apt-get install --assume-yes libcurl4
WORKDIR /bedrock-server
COPY --from=unzip /bedrock-server .
ENV LD_LIBRARY_PATH=.
CMD ./bedrock_server
