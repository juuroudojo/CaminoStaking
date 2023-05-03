// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.9;

// import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
// import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableMapUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
// import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

// import "hardhat/console.sol";

// contract CaminoHub is 
//     Initializable,
//     PausableUpgradeable,
//     AccessControlUpgradeable,
//     UUPSUpgradeable 
// {
//     using AddressUpgradeable for address;
//     using SafeERC20Upgradeable for IERC20Upgradeable;
//     using EnumerableMapUpgradeable for EnumerableMapUpgradeable.AddressToUintMap;

//     bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

//     //flag for upgrades availability
//     bool public upgradeStatus;

//     // Define a mapping to store the Merkle root for each token
//     mapping(address => bytes32) public merkleRoots;

//     // Event emitted when a Merkle root is set for a token
//     event MerkleRootSet(address indexed token, bytes32 merkleRoot);

//     // Event emitted when a user claims an airdrop
//     event AirdropClaimed(address indexed user, address indexed token, uint256 amount);

//     function initialize() public initializer {
//         __Pausable_init();
//         __AccessControl_init();
//         __UUPSUpgradeable_init();

//         _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
//         _setupRole(UPGRADER_ROLE, msg.sender);
//     }

//     function initializeAirdrop(address token, uint256 amount) public {
//         IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
//     }

//     function launchAirdrop(address token, uint256 amount, bytes32 merkleRoot) external {
//         // Transfer the tokens to the contract
//         IERC20(token).transferFrom(msg.sender, address(this), amount);

//         // Set the Merkle root for the token
//         merkleRoots[token] = merkleRoot;
//         emit MerkleRootSet(token, merkleRoot);

//         // Emit an event to indicate that the airdrop has been initialized
//         emit AirdropInitialized(token, amount);
//     }

//     function claimAirdrop(address token, uint256 amount, bytes32[] memory merkleProof) external {
//         // Get the Merkle root for the token
//         bytes32 merkleRoot = merkleRoots[token];

//         // Verify the Merkle proof
//         bytes32 node = keccak256(abi.encodePacked(msg.sender, amount));
//         require(MerkleProof.verify(merkleProof, merkleRoot, node), "Invalid Merkle proof");

//         // Transfer the tokens to the user
//         IERC20(token).transfer(msg.sender, amount);

//         // Emit an event to indicate that the user has claimed the airdrop
//         emit AirdropClaimed(msg.sender, token, amount);
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

//     function claimAirDrop(address token, uint256 amount) public {
        
//     }

//     function previewAirDrop(address token) public view returns(uint256 amount) {
         
//     }
// }
