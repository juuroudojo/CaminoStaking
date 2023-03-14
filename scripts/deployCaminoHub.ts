import {ethers, upgrades} from "hardhat";

async function main() {
    const Hub = await ethers.getContractFactory("CaminoHub");

    const hub = await upgrades.deployProxy(Hub,
        [],
        {initializer: 'initialize', kind: 'uups'}
        );

    console.log(
      "CaminoHub deployed to:", hub.address
    )
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });