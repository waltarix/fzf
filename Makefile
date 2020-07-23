SHELL       := bash
GO          ?= go
GOOS        ?= $(word 1, $(subst /, " ", $(word 4, $(shell go version))))

MAKEFILE    := $(realpath $(lastword $(MAKEFILE_LIST)))
ROOT_DIR    := $(shell dirname $(MAKEFILE))
SOURCES     := $(wildcard *.go src/*.go src/*/*.go) $(MAKEFILE)

VERSION     := $(shell awk -F= '/version=/ {print $$2; exit}' install)
REVISION    := $(shell git log -n 1 --pretty=format:%h -- $(SOURCES))
BUILD_FLAGS := -a -ldflags "-s -w -X main.version=$(VERSION) -X main.revision=$(REVISION)" -tags "$(TAGS)"

BINARY64    := fzf-$(GOOS)_amd64
BINARYARM64 := fzf-$(GOOS)_arm64

# https://en.wikipedia.org/wiki/Uname
UNAME_M ?= $(shell uname -m)
ifeq ($(UNAME_M),x86_64)
	BINARY := $(BINARY64)
else ifeq ($(UNAME_M),amd64)
	BINARY := $(BINARY64)
else ifeq ($(UNAME_M),arm64)
	BINARY := $(BINARYARM64)
else
$(error Build on $(UNAME_M) is not supported, yet.)
endif

ARCHIVE := $(subst fzf-,fzf-$(VERSION)-,$(BINARY)).tar.xz

all: target/$(BINARY)

test: $(SOURCES)
	SHELL=/bin/sh GOOS= CGO_ENABLED=0 $(GO) test -v -tags "$(TAGS)" \
				github.com/junegunn/fzf/src \
				github.com/junegunn/fzf/src/algo \
				github.com/junegunn/fzf/src/tui \
				github.com/junegunn/fzf/src/util

install: bin/fzf

build:
	goreleaser --rm-dist --snapshot

clean:
	$(RM) -r dist target

target/$(BINARY64): $(SOURCES)
	GOARCH=amd64 $(GO) build $(BUILD_FLAGS) -o $@

target/$(BINARYARM64): $(SOURCES)
	GOARCH=arm64 $(GO) build $(BUILD_FLAGS) -o $@

bin/fzf: target/$(BINARY) | bin
	cp -f target/$(BINARY) bin/fzf

docker:
	docker build -t fzf-arch .
	docker run -it fzf-arch tmux

docker-test:
	docker build -t fzf-arch .
	docker run -it fzf-arch

update:
	$(GO) get -u
	$(GO) mod tidy

release-gh: bin/fzf
	tar -Jcvf $(ARCHIVE) bin plugin

.PHONY: all build test install clean docker docker-test update release-gh
