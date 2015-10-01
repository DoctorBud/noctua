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

## Workbenches.
WORKBENCHES ?= 

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
BARISTA_REPL_PORT ?= 9090
MINERVA_PORT ?= 6800

## URL for users.yaml.
#GO_USER_METADATA_FILE ?= 'https://s3.amazonaws.com/go-public/metadata/users.json'
GENEONTOLOGY_CATALOG ?= ~/local/src/svn/geneontology.org/trunk/ontology/extensions/catalog-v001.xml

## BBOP JS paths.
BBOP_JS ?= ../bbop-js/
BBOPX_JS ?= ../bbopx-js/
BBOP_GRAPH_NOCTUA ?= ../bbop-graph-noctua/

## Minerva paths.
MINERVA_SERVER ?= ../minerva/
NOCTUA_MODELS ?= /home/sjcarbon/local/src/git/noctua-models/models/
#MINERVA_LABEL_RESOLUTION ?= 'http://geneontology.org'
GOLR_SERVER ?= 'http://golr.berkeleybop.org/'
MINERVA_LABEL_RESOLUTION ?= 'http://golr.berkeleybop.org/'

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
#	cd $(BBOP_JS) && make bundle
#	cd $(BBOPX_JS) && make bundle
	cd
#	cp $(BBOP_JS)/staging/bbop.js static/
#	cp $(BBOPX_JS)/staging/bbopx.js static/

## Note, these two are useful for ultra-fast prototyping, bypassing the
## necessary NPM steps for the server code.
.PHONY: patch-test-js
patch-test-js:
	cp $(BBOP_JS)/staging/bbop.js node_modules/bbop/bbop.js
	cp $(BBOPX_JS)/staging/bbopx.js node_modules/bbopx/bbopx.js
	cp $(BBOP_GRAPH_NOCTUA)/lib/edit.js node_modules/bbop-graph-noctua/lib/edit.js

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
	WORKBENCHES=$(WORKBENCHES) MINERVA_DEFINITION=$(MINERVA_DEFINITION) BARISTA_LOCATION=$(BARISTA_LOCATION) GOLR_SERVER=$(GOLR_SERVER) $(NODE_BIN) noctua.js

## Start without copying bbop-js over.
.PHONY: start-noctua
start-noctua:
	WORKBENCHES=$(WORKBENCHES) MINERVA_DEFINITION=$(MINERVA_DEFINITION) BARISTA_LOCATION=$(BARISTA_LOCATION) GOLR_SERVER=$(GOLR_SERVER) $(NODE_BIN) noctua.js

###
### Commands/environment for Barista messaging server.
###

.PHONY: start-barista-dev
start-barista-dev: assemble-app
	BARISTA_PORT=$(BARISTA_PORT) BARISTA_REPL_PORT=$(BARISTA_REPL_PORT) $(NODE_BIN) barista.js

.PHONY: start-barista
start-barista:
	BARISTA_PORT=$(BARISTA_PORT) BARISTA_REPL_PORT=$(BARISTA_REPL_PORT) $(NODE_BIN) barista.js

###
### Commands/environment for Minerva data server.
###

.PHONY: start-minerva-go
start-minerva-go:
	java -Xmx4G -cp ./java/lib/minerva-cli.jar org.geneontology.minerva.server.StartUpTool --use-request-logging --slme-elk --skip-class-id-validation --golr-labels $(MINERVA_LABEL_RESOLUTION) -c $(GENEONTOLOGY_CATALOG) -g http://purl.obolibrary.org/obo/go/extensions/go-lego.owl --set-important-relation-parent http://purl.obolibrary.org/obo/LEGOREL_0000000 -f $(NOCTUA_MODELS) --port $(MINERVA_PORT)

###
### Gulp-based workflows.
###

.PHONY: install
install:
	npm install

## Documentation for JavaScript.
.PHONY: docs
docs: install
	./node_modules/.bin/gulp doc

## Tests with mocha/chai.
.PHONY: tests
tests:
	./node_modules/.bin/gulp test

## Build with browserify.
.PHONY: build
build:
	./node_modules/.bin/gulp build
