build:
	goreleaser --rm-dist --snapshot --skip-publish

test:
	go test -v ./...

clean:
	$(RM) -r dist

.PHONY: build test clean
