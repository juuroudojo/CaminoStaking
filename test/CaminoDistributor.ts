import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { ethers, network, upgrades } from "hardhat";
import { BigNumber, BigNumberish} from "ethers";

async function getImpersonatedSigner(address: string): Promise<SignerWithAddress> {
    await ethers.provider.send(
      'hardhat_impersonateAccount',
      [address]
    );
  
    return await ethers.getSigner(address);
  }
  
  async function skipDays(days: number) {
    ethers.provider.send("evm_increaseTime", [days * 86400]);
    ethers.provider.send("evm_mine", []);
  }
  
  async function sendEth(users: SignerWithAddress[]) {
    let signers = await ethers.getSigners();
  
    for (let i = 0; i < users.length; i++) {
      await signers[0].sendTransaction({
        to: users[i].address,
        value: parseEther("1.0")
  
      });
    }
  }

  describe("CaminoDistributor tests", () => {

  }
   );