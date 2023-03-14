import {ethers, upgrades} from "hardhat";

async function main() {
    const Airdrop = await ethers.getContractFactory("SimpleAirdropHandler");

    const airdrop = await upgrades.deployProxy(Airdrop,
        [],
        {initializer: 'initialize', kind: 'uups'}
        );

    console.log(
      "AirdropHandler deployed to:", airdrop.address
    )
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });