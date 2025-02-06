.PHONY: all
all: build

.PHONY: build
build:
	npx hardhat compile

.PHONY: checksum
checksum:
	for f in ./build/contracts/*.json; do echo -n "$$f "; jq -j .deployedBytecode $$f | shasum; done

.PHONY: test
test:
	npx hardhat test --typecheck

.PHONY: lint
lint:
	 solhint 'contracts/**/*.sol'