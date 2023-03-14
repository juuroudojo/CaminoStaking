import {ethers, upgrades} from "hardhat"
import { Test } from "mocha";

async function main() {
    const Testtoken = await ethers.getContractFactory("RukiaToken");
    const token = await Testtoken.deploy(ethers.utils.parseEther("3"));

    console.log(
      "Testtoken deployed to:", token.address
    )
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });