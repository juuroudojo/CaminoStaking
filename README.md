<p align="center">
  <img src="https://github.com/juuroudojo/images/blob/main/camino-logo.png" height="150" />
</p>

<br/>

# Tokenomics on Camino Network

## [DEPLOYMENT GUIDE](https://github.com/juuroudojo/CaminoTokenomics/blob/master/DEPLOYMENT.MD)

The repository displays basic implementations of different contracts covering different parts of liquidity dynamics. Below you can find a detailed description of each contract, as well as a guide on what each of them is and how to work with it.

## Table of Contents

1. [Introduction](#introduction)
2. [Prerequisites](#prerequisites)
3. [Project Structure](#project-structure)
4. [Installation and Setup](#installation-and-setup)
5. [User Guide](#user-guide)
   - Unit contracts
   - Integrated abstract ecosystem
6. [Contributing](#contributing)
7. [License and Contact Information](#license-and-contact-information)

## Description

Repo contains:

`samples/`
- LiquidityPool.sol -
Ground zero implementation of a Liquidity pool. A basic example covering the structure of a liquidity pool, allowing for understanding how it works. An actual implementation ready for production requires a complex approach, with a predefined mathematical model serving as an AMM, preexisting liquidity, advanced security measures, and more.

- Staking.sol -
A basic implementation of a staking contract. It allows users to stake their tokens and receive rewards in return. The contract is a good example of how to implement a staking contract, showcasing the structure of it, but is note representative of the final product, as far as it exists in a vacuum, without the preexisting infrastructure supporting liquidity and other aspects of the tokenomics.

`sampleIntegrated/`
An integrated infrastructure of contracts, displaying how the contracts are orchestrated in a way that allows them to interact with each other, creating a single ecosystem. Unlike contracts in ''samples'', which are a minimalistic implementations serving as ways of understanding the infrastructure, the ecosystem is operational but isn't representative of the projects on the market. In order to be production-ready, contracts in `samples` need to have additional features and infrastructure implemented, while in `sampleIntegrated` the aforementioned required infrastructure is already implemented, but can be deemed as 'mocked'. A lot of the parts of this ecosystem exist for the sole purpose of replacing the nonexistent infrastructure in order to show the contracts in process, working as a single infrastructure.

Refer to [User Guide](#user-guide) for a detailed description of how to interact with this ecosystem.

## Prerequisites

To run and interact with these projects, you will need:

- [Node.js](https://nodejs.org/en/download/) (version 14.x or higher)
- [npm](https://www.npmjs.com/get-npm) (usually bundled with Node.js)
- [Hardhat](https://hardhat.org/getting-started/#overview) development environment
- [Camino Wallet](https://wallet.camino.foundation/) (Should be KYC verified)

## Project Structure

The repository is organized as follows:

- `contracts/` - Contains the Solidity smart contracts implementing the token standards and marketplace:
  - `sampleIntegrated/` - Contains an abstract implementation of integrating simple contracts into 1 ecosystem.
  - `samples/` - Contains basic implementations of contracts covering different tokenomics aspects.
  - `mocks/` - Contains mock contracts for testing purposes.
  
- `test/` - Contains the test scripts for the smart contracts. Also a good place to look for examples of how to interact with the contracts.
- `scripts/` - Contains the Hardhat deployment scripts.

## Installation and Setup

1. Clone the repository:

```bash
git clone https://github.com/juuroudojo/CaminoStaking.git
```

2. Install the required dependencies:

```bash
cd CaminoStaking
npm install
```

3. Create a `.env` file in the root directory and configure it with your MetaMask wallet's private key and a [Columbus testnet]() API key for deploying to testnets:

```dotenv
PRIVATE_KEY="your_private_key"
COLUMBUS_API_KEY="your_columbus_api_key"
```

4. Compile the smart contracts:

```bash
npx hardhat compile
```

5. Deploy the contracts to a local test network or a public testnet using Hardhat:

```bash
npx hardhat run scripts/deploy.ts --network localhost
```

## User Guide

Let's walk through some use cases for the contracts in this repository.

### Unit contracts


1. **LiquidtyPool.sol** 
- Let's try to go through the process of exchanging the tokens using liqudity pool. We'll have 3 participants: Joel, Nicola and Giannis. Joel and Nicola will be providing liquidity to the pool, while Giannis will be exchanging his tokens for the ones provided by Joel and Nicola.

```typescript
// Joel deposits Atoken to the pool
await liquidityPool.addLiquidity(1, 1000);
```

```typescript
// Nicola deposits Btoken to the pool
await liquidityPool.addLiquidity(2, 1000);
```

```typescript
// Giannis exchanges his Atokens for Btokens
await liquidityPool.swap(1, 2, 100);
```


## Contributing

If you'd like to contribute to the project, please submit an issue or create a pull request with your proposed changes.

## License and Contact Information

This project is licensed under the [MIT License](LICENSE). For any questions or suggestions, please contact the repository owner.

