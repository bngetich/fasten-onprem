#########################################################################################################
# Frontend Build
#########################################################################################################
FROM node:18.9.0 as frontend-build
WORKDIR /usr/src/fastenhealth/frontend
#COPY frontend/package.json frontend/yarn.lock ./
COPY frontend/package.json ./
#COPY frontend/yarn.lock ./
RUN yarn config set registry "http://registry.npmjs.org" \
    && yarn install --frozen-lockfile --network-timeout 100000
COPY frontend/ ./
RUN yarn run build -- --configuration sandbox --output-path=../dist

#########################################################################################################
# Backend Build
#########################################################################################################
FROM golang:1.18 as backend-build
WORKDIR /go/src/github.com/fastenhealth/fastenhealth-onprem
COPY . .

RUN go mod vendor \
    && go install github.com/golang/mock/mockgen@v1.6.0 \
    && go generate ./... \
    && go vet ./... \
    && go test ./...
RUN CGO_ENABLED=0 go build -o /go/bin/fasten ./backend/cmd/fasten/

# create folder structure
RUN mkdir -p /opt/fasten/db \
  && mkdir -p /opt/fasten/web \
  && mkdir -p /opt/fasten/config \
  && curl -o /opt/fasten/db/fasten.db -L https://github.com/fastenhealth/testdata/raw/main/fasten.db


#########################################################################################################
# Distribution Build
#########################################################################################################
FROM couchdb:3.2

ARG S6_ARCH=amd64
RUN curl https://github.com/just-containers/s6-overlay/releases/download/v1.21.8.0/s6-overlay-${S6_ARCH}.tar.gz -L -s --output /tmp/s6-overlay-${S6_ARCH}.tar.gz \
    && tar xzf /tmp/s6-overlay-${S6_ARCH}.tar.gz -C / \
    && rm -rf /tmp/s6-overlay-${S6_ARCH}.tar.gz

COPY /docker/couchdb/local.ini /opt/couchdb/etc/
COPY /docker/rootfs /

WORKDIR /opt/fasten/
COPY --from=backend-build  /opt/fasten/ /opt/fasten/
COPY --from=frontend-build /usr/src/fastenhealth/dist /opt/fasten/web
COPY --from=backend-build /go/bin/fasten /opt/fasten/fasten
COPY LICENSE.md /opt/fasten/LICENSE.md
COPY config.yaml /opt/fasten/config/config.yaml

ENTRYPOINT ["/init"]





