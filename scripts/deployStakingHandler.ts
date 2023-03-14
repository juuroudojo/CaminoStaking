import {ethers, upgrades} from "hardhat";

async function main() {
    const Handler = await ethers.getContractFactory("SimpleStakingHandler");
    const hubaddr = "0x5f64a6e9e7f7f9f1f1b9b1f2e6f2f3f4f5f5f6f7";

    const handler = await upgrades.deployProxy(Handler,
        [hubaddr],
        {initializer: 'initialize', kind: 'uups'}
        );

    console.log(
      "StakingHandler deployed to:", handler.address
    )
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });