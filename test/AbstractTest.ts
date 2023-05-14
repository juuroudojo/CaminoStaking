import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { expect } from "chai";
import { parseEther, parseUnits } from "ethers/lib/utils";
import { ethers, network, upgrades } from "hardhat";
import { BigNumber, BigNumberish} from "ethers";
import {LiquidityPool, Staking, TestToken, IERC20} from '../typechain'

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
    let owner: SignerWithAddress
    let user1: SignerWithAddress
    let user2: SignerWithAddress
    let lp: LiquidityPool
    let st: Staking
    
    let token1: IERC20
    let token2: IERC20
    let lptoken: IERC20

    before (async function() {
      [owner, user1, user2] = await ethers.getSigners();
    })

    beforeEach(async function() {

      await network.provider.request({
        method: "hardhat_reset",
        params: [{
          forking: {
            enabled: true,
            jsonRpcUrl: process.env.POLYGON_FORKING_URL as string,
            //you can fork from last block by commenting next line
            blockNumber: 42655252,
          },
        },],
      });

      let Token1 = await ethers.getContractFactory("TestToken")
      token1 = await Token1.deploy(ethers.utils.parseEther("1000000"))
      token2 = await Token1.deploy(ethers.utils.parseEther("1000000"))

      let Lp = await ethers.getContractFactory("LiquidityPool")
      lp = await Lp.deploy(token1.address, token2.address)

      let Lptoken = await ethers.getContractFactory("LPToken")
      lptoken = await Lptoken.deploy(lp.address)

      let St = await ethers.getContractFactory("Staking")
      // startTime: 	Sat May 13 2023 09:55:45 GMT+0000
      // endTime:     Sat May 27 2023 10:50:45 GMT+0000
      st = await St.deploy(token1.address, 168391745, 1685184645, ethers.utils.parseEther("10000"));

      await lp.setLpToken(lptoken.address)
    })

    describe("Liquidity Pool", async() => {
      it("Should add liquidity", async() => {
        await token1.approve(lp.address, ethers.utils.parseEther("100"))
        await lp.addLiquidity(ethers.utils.parseEther("100"), 0)
        expect(await lptoken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("100"))
        expect(await token1.balanceOf(lp.address)).to.equal(ethers.utils.parseEther("100"))
      })

      it("Should deposit 2 tokens correctly", async() => {
        await token1.approve(lp.address, ethers.utils.parseEther("100"))
        await token2.approve(lp.address, ethers.utils.parseEther("100"))
        await lp.addLiquidity(ethers.utils.parseEther("100"), ethers.utils.parseEther("100"))
        expect(await lptoken.balanceOf(owner.address)).to.equal(ethers.utils.parseEther("200"))
      })

      it("Should swap token1 for token2", async() => {
        await token2.transfer(lp.address, ethers.utils.parseEther("250"))
        let balanceBefore = await token2.balanceOf(owner.address)
        await token1.approve(lp.address, ethers.utils.parseEther("100"))
        await lp.addLiquidity(ethers.utils.parseEther("100"), 0)
        await lp.withdrawTokenB(ethers.utils.parseEther("100"))
        expect(await token2.balanceOf(owner.address)).to.equal(balanceBefore.add(ethers.utils.parseEther("100")))
      })

      it("Should swap token2 for token1", async() => {
        await token1.transfer(lp.address, ethers.utils.parseEther("250"))
        let balanceBefore = await token1.balanceOf(owner.address)
        await token2.approve(lp.address, ethers.utils.parseEther("100"))
        await lp.addLiquidity(0, ethers.utils.parseEther("100"))
        await lp.withdrawTokenA(ethers.utils.parseEther("100"))
        expect(await token1.balanceOf(owner.address)).to.equal(balanceBefore.add(ethers.utils.parseEther("100")))
      })
    })

    describe("Staking", async() => {
      it("Should initialise staking", async() => {
        await token1.approve(st.address, ethers.utils.parseEther("100"))
        await st.stake(ethers.utils.parseEther("100"))
        expect(await st.totalStaked()).to.equal(ethers.utils.parseEther("100"))
      })

      it("Should stake token", async() => {
        await token1.approve(st.address, ethers.utils.parseEther("100"))
        await st.stake(ethers.utils.parseEther("100"))
        expect(await st.totalStaked()).to.equal(ethers.utils.parseEther("100"))
      })

      it("Should not unstake tokens", async() => {
        await token1.approve(st.address, ethers.utils.parseEther("100"))
        await st.stake(ethers.utils.parseEther("100"))
        await expect(st.unstake()).to.be.revertedWith("Staking period not yet ended")
      })

      it("Should calculate rewards correctly", async() => {
        await token1.transfer(user1.address, ethers.utils.parseEther("30"))
        await token1.approve(st.address, ethers.utils.parseEther("50"))
        await token1.connect(user1).approve(st.address, ethers.utils.parseEther("30"))
        await st.stake(ethers.utils.parseEther("40"))
        await st.connect(user1).stake(ethers.utils.parseEther("20"))
        await skipDays(40)
        await st.connect(user1).unstake()
      })
    })
  })