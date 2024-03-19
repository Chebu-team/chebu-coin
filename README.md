## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy
#### Sepolia
```shell
$ forge script script/DeployCHEBU.s.sol:DeployScriptCHEBU --rpc-url sepolia  --account ttwo --sender 0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3 --broadcast --verify
```

### Cast in Sepolia

```shell
$ # BalanceOf stable for trade
$ cast call 0xE3cfED0fbCDB7AaE09816718f0f52F10140Fc61F "balanceOf(address)" 0xDDA2F2E159d2Ce413Bd0e1dF5988Ee7A803432E3 --rpc-url sepolia

$ cast send 0xE3cfED0fbCDB7AaE09816718f0f52F10140Fc61F "approve(address,uint256)" 0xf35b8249Ef91317f06E67c887B38483089c18724 1000000000000 --rpc-url sepolia --account ttwo 

$ cast send 0xf35b8249Ef91317f06E67c887B38483089c18724 "mintTokensForExactStable(uint256)" 10000000 --rpc-url sepolia --account ttwo 

burnExactTokensForStable
$ cast send 0xf35b8249Ef91317f06E67c887B38483089c18724 "burnExactTokensForStable(uint256)" 1000000000000000000 --rpc-url sepolia --account ttwo 
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
