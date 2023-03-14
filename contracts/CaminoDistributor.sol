// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppilin/contracts/token/ERC20/IERC20.sol";

// contract MultiTokenAirdrop is AccessControl {
//     address public owner;
//     uint256 public totalTokensAirdropped;
    
//     // Mapping to keep track of which addresses have received which tokens
//     mapping(address => mapping(address => bool)) public tokensReceived;

//     // Grants Default Adming Role to CaminoHub contract, it directs the process of airdropping

//     constructor(address multisig, address[] memory accounts) {
//         owner = msg.sender;
//         _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
//         _setupRole(DEFAULT_ADMIN_ROLE, multisig);
//         for (uint256 i = 0; i < accounts.length; i++) {
//             _setupRole(DEFAULT_ADMIN_ROLE, accounts[i]);
//         }
//        grantRole(DEFAULT_ADMIN_ROLE, multisig);
//     }


//     // Function to airdrop multiple tokens to a list of addresses
//     function multiTokenAirdrop(
//         address[] memory tokenAddresses,
//         uint256[] memory tokenAmounts,
//         address[] memory recipientAddresses
//     ) external onlyRole(DEFAULT_ADMIN_ROLE) {
//         require(
//             tokenAddresses.length == tokenAmounts.length &&
//             tokenAddresses.length == recipientAddresses.length,
//             "Input lengths must match."
//         );

//         for (uint256 i = 0; i < tokenAddresses.length; i++) {
//             address tokenAddress = tokenAddresses[i];
//             uint256 tokenAmount = tokenAmounts[i];
//             address recipientAddress = recipientAddresses[i];

//             require(
//                 IERC20(tokenAddress).balanceOf(address(this)) >= tokenAmount &&
//                 !tokensReceived[recipientAddress][tokenAddress],
//                 "Insufficient balance or tokens already received."
//             );

//             require(
//                 IERC20(tokenAddress).transfer(recipientAddress, tokenAmount),
//                 "Token transfer failed."
//             );

//             tokensReceived[recipientAddress][tokenAddress] = true;

//             totalTokensAirdropped += tokenAmount;
//         }
//     }
// }
