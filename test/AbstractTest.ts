import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { ethers, network, upgrades } from "hardhat";
import { BigNumber, BigNumberish} from "ethers";
import {LiquidityPool, Staking, TestToken} from '../typechain'

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

  describe("Unit contracts tests", () => {
    let token1: TestToken
    let token2: TestToken
    let owner: SignerWithAddress
    let user1: SignerWithAddress
    let user2: SignerWithAddress
    let lp: LiquidityPool
    let st: Staking

    before (async function() {
      [owner, user1, user2] = await ethers.getSigners();
    })

    beforeEach(async function() {
      let Token1 = await ethers.getContractFactory("TestToken")
      token1 = await Token1.deploy()
      token2 = await Token1.deploy()

      let Lp = await ethers.getContractFactory("LiquidityPool")
      lp = await Lp.deploy(token1.address, token2.address)

      let St = await ethers.getContractFactory("Staking")
      st = await St.deploy(token1.address, 323232, 333333, 1000000000)

    })

    describe("Liquidity Pool", async() => {

      it("Should add liquidity", async() => {

      })

      it("Should swap token1 for token2", async() => {

      })

      it("Should swap token2 for token1", async() => {

      })
    })

    describe("Staking", async() => {
      it("Should initialise staking", async() => {

      })

      it("Should stake token", async() => {

      })

      it("Should not stake unsupported tokens", async() => {

      })

      it("Should unstake tokens", async() => {

      })

      it("Should calculate rewards correctly", async() => {
        
      })
    })
  }
   );