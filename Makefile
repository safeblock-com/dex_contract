generate:
	solc --abi ./src/MultiswapRouter.sol -o build/MultiswapRouter/abi --overwrite
	solc --bin ./src/MultiswapRouter.sol -o build/MultiswapRouter/bin --overwrite
	abigen --bin=build/MultiswapRouter/bin/MultiswapRouter.bin --abi=build/MultiswapRouter/abi/MultiswapRouter.abi --pkg=contract --out=build/contract.go
