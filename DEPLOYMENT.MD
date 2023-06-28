# Deployment Guide

## Table of Contents

- [Introduction](#introduction)
- [Deployment Structure](#deployment-structure)
- [Smart Contracts](#smart-contracts)
- [Columbus Ecosystem](#columbus-ecosystem)
- [Deployment Steps](#deployment-steps)
- [Additional Info](#additional-info)
- [Contributions](#contributions)

## Introduction

The repo consists of many templates each one exploring different topics and created with the purpose of walking the user through a particular branch of the blockchain ecosystem. As a result, the repo is quite big and can be overwhelming to navigate. Thus, the approach to deployment is chosen to balance out the coverage of all the aspects and creating a friendly user experience.

## Deployment Structure

The approach chosen for the Tokenomics repo comes down to a set of unit contracts walking the user through some blockchain interactions. The integrated ecosystem is only present on testnet. It only makes sense, as far as the ecosystem is big, interconnected, has some gaps for mocking purposes and a bit costly in terms of gas. 

## Smart Contracts

<img src=https://github.com/juuroudojo/images/blob/main/leela.png/>

- **`LiquidityPool.sol`** - Basic implementation of a Liquidity Pool solution omitting complex mathematical algorithms providing AMM mechanisms. User is introduced to the concept of a liquidity pool, liquidity pool tokens, exchange mechanisms, tokenomics basics, etc.

- **`Staking.sol`** - Basic implementation of a Staking platform. Allows anyone to participate in a staking 

- **`TestToken.sol`** - Simple ERC20 token which is used in both LiquidityPool.sol and Staking.sol. Permissionless, meaning anyone can mint tokens and use them to play around with staking. This approach also creates a realistic environment where the user can see how the platform works in dynamic conditions.

- **`LPToken.sol`** - Liquidity Pool token, which is a part of a Liquidity Pool.

## Columbus Ecosystem

Testnet prototype is different and covers more aspects, including the integrated ecosystem supporting Aidrops and Stakings. Although, it's quite experimental, there is some non-representative logic, intentionally neglected inconsistencies. The purpose of the testnet is to provide a playground for the user to interact with the ecosystem in a simulated integrated environment.

- **`StakingHandler.sol`** - Manages the Staking information in integration with Hub

- **`AirdropHandler.sol`** - Manages the Aidrop processes in integration with Hub

- **`Hub.sol`** - Orchestrates the system. Endpoint for user interactions. 

- **`TestToken.sol`** - Simple ERC20 token which is used in both LiquidityPool.sol and Staking.sol. Permissionless, meaning anyone can mint tokens and use them to play around with staking. This approach also creates a realistic environment where the user can see how the platform works in dynamic conditions.

- **`LPToken.sol`** - Liquidity Pool token, which is a part of a Liquidity Pool.


## Additional Info

Roling and permissions is one of the part of the infrastructure. You can find more info on it in here. The system is maintained by our team. If you face any issues, want some additional info/explanation or additional opportuinities to interact with the infrastructure feel free to reach out to us on [Discord](https://discord.gg/).



## Contributions

Difficulties and questions you face interacting with the templates is a valuable feedback for us. Reach out to us on [Discord](https://discord.gg/) or create an issue on GitHub. We will be happy to help you out.
