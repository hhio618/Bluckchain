all: codegen build node create deploy

ensure-abi:
	cp ../contracts/abis/PredictionMarket.json ./abis/
codegen:
	graph codegen

build:
	graph build

node:
	docker-compose up -d

create:
	graph create --node http://127.0.0.1:8020 bluckchain/PredictionMarket

deploy:
	graph deploy --node http://127.0.0.1:8020 --ipfs http://127.0.0.1:5001 bluckchain/PredictionMarket

