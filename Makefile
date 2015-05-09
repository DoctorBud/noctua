####
#### Example of running noctua again public servers.
####   MINERVA_DEFINITION=minerva_public BARISTA_LOCATION=http://barista.berkeleybop.org:3400 make start-noctua
####
#### Example of running locally for (GO) dev:
####   GENEONTOLOGY=~/local/src/svn/geneontology.org/trunk/ make start-minerva-go
####   make start-barista-dev
####   make start-noctua
####
#### TODO:
#### : npm bin gulp
####

## Variable to pass the location definition Minerva server server to
## the deploying app.
MINERVA_DEFINITION ?= minerva_local

## Variable to define where Noctua looks for Barista.
BARISTA_LOCATION ?= http://localhost:3400

## Emergency override for exotic Noctua deployments; noctua.js
## internal.
NOCTUA_HOST ?= 127.0.0.1
## Also see: PORT in the noctus.js code; used by Heroku in some cases?

## Variable to define the port that Barista starts on.
BARISTA_PORT ?= 3400

## URL for users.yaml.
GO_USER_METADATA_FILE ?= 'https://s3.amazonaws.com/go-public/metadata/users.json'

## BBOP JS paths.
BBOP_JS ?= ../bbop-js/
BBOPX_JS ?= ../bbopx-js/

## OWLTools paths.
OWLTOOLS ?= ../owltools/
GENEONTOLOGY ?= ../geneontology/trunk/

## Testing.
TESTS = \
 $(wildcard js/*.js.tests)
TEST_JS = rhino
TEST_JS_FLAGS = -modules static/bbop.js -modules static/bbopx.js -opt -1

NODE_BIN ?= node

###
### Building.
###

.PHONY: refresh-metadata
refresh-metadata:
	wget --no-check-certificate $(GO_USER_METADATA_FILE) && mv users.json config/

## Note, last two are useful for ultra-fast prototyping, bypassing the
## necessary NPM steps for the server code.
.PHONY: assemble-app
assemble-app:
	cd $(BBOP_JS) && make bundle
	cd $(BBOPX_JS) && make bundle
	cd
	cp $(BBOP_JS)/staging/bbop.js static/
	cp $(BBOPX_JS)/staging/bbopx.js static/

## Note, these two are useful for ultra-fast prototyping, bypassing the
## necessary NPM steps for the server code.
.PHONY: patch-test-js
patch-test-js:
	cp $(BBOP_JS)/staging/bbop.js node_modules/bbop/bbop.js
	cp $(BBOPX_JS)/staging/bbopx.js node_modules/bbopx/bbopx.js

###
### Tests.
###

## Have to do a little something with basename to make sure we can
## deal with the odd pre-bbop namespacey modules.
.PHONY: test $(TESTS)
test: assemble-app $(TESTS)
$(TESTS):
	echo "trying: $@"
	$(TEST_JS) $(TEST_JS_FLAGS) -f $(@D)/$(basename $(@F)) -f $(@D)/$(@F)

.PHONY: pass
pass:
	make test | grep -i fail; test $$? -ne 0

###
### Commands/environment for Noctua application server.
###

##
.PHONY: start-noctua-dev
start-noctua-dev: assemble-app
	MINERVA_DEFINITION=$(MINERVA_DEFINITION) BARISTA_LOCATION=$(BARISTA_LOCATION) $(NODE_BIN) noctua.js

## Start without copying bbop-js over.
.PHONY: start-noctua
start-noctua:
	MINERVA_DEFINITION=$(MINERVA_DEFINITION) BARISTA_LOCATION=$(BARISTA_LOCATION) $(NODE_BIN) noctua.js

###
### Commands/environment for Barista messaging server.
###

.PHONY: start-barista-dev
start-barista-dev: assemble-app
	BARISTA_PORT=$(BARISTA_PORT) $(NODE_BIN) barista.js

.PHONY: start-barista
start-barista:
	BARISTA_PORT=$(BARISTA_PORT) $(NODE_BIN) barista.js

###
### Commands/environment for Minerva data server.
###

.PHONY: start-minerva-go
start-minerva-go:
	cd $(OWLTOOLS)/MolecularModelServer/bin && ./build-server.sh
	cd $(OWLTOOLS)/MolecularModelServer/bin && ./start-go-minerva.sh $(GENEONTOLOGY)

.PHONY: start-minerva-go-fast
start-minerva-go-fast:
	cd $(OWLTOOLS)/MolecularModelServer/bin && ./start-go-minerva.sh $(GENEONTOLOGY)

###
### Gulp-based workflows.
###

.PHONY: install
install:
	npm install

## Documentation for JavaScript.
.PHONY: docs
docs: install
	node ./node_modules/gulp/bin/gulp.js doc

## Documentation for JavaScript.
.PHONY: tests
tests:
	node ./node_modules/gulp/bin/gulp.js test
