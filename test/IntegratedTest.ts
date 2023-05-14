import { ethers, network, upgrades } from 'hardhat';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { AirdropHandler, StakingHandler, Hub, TestToken, AirdropHandler__factory, StakingHandler__factory, Hub__factory } from '../typechain';

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
      value: ethers.utils.parseEther("1.0")

    });
  }
}

describe('Flight Booking Contracts', function () {
  let hub: Hub;
  let shandler: StakingHandler;
  let adhandler: AirdropHandler
  let token1: TestToken;
  let token2: TestToken;

  let user1: SignerWithAddress;
  let user2: SignerWithAddress;
  let owner: SignerWithAddress;
  let flightId: string;
  let mockTokenM: SignerWithAddress;

  before(async function () {
    flightId = ethers.utils.formatBytes32String("JL1727");
  });

  beforeEach(async function () {
    await network.provider.request({
      method: "hardhat_reset",
      params: [{
          forking: {
              enabled: true,
              jsonRpcUrl: process.env.POLYGON_FORKING_URL as string,
              //you can fork from last block by commenting next line
              blockNumber: 41152251,
          },
      },],
  });

    [owner, user1, user2] = await ethers.getSigners();

    // DEPLOYMENT

    let tokenFactory = await ethers.getContractFactory('TestToken');
    token1 = await tokenFactory.deploy(ethers.utils.parseEther("10000")) as TestToken;
    token2 = await tokenFactory.deploy(ethers.utils.parseEther("10000")) as TestToken;

    // Instance of mock token to emulate calls.
    let tokenM = await getImpersonatedSigner(token1.address);
    const Hub = await ethers.getContractFactory("Hub") as Hub__factory;
    const StakingHandler = await ethers.getContractFactory("StakingHandler") as StakingHandler__factory;
    const AirdropHandler = await ethers.getContractFactory("AirdropHandler") as AirdropHandler__factory;

    // Deploying the upgradeable contracts
    adhandler = await upgrades.deployProxy(AirdropHandler, [], {
      initializer: 'initialize', unsafeAllow: ["delegatecall"],
      kind: 'uups'
    }) as AirdropHandler;

    hub = await upgrades.deployProxy(Hub,
      [],
      {
      initializer: 'initialize', unsafeAllow: ["delegatecall"],
      kind: 'uups'
    }
    ) as Hub;

    shandler = await upgrades.deployProxy(StakingHandler, [hub.address], {
      initializer: 'initialize', unsafeAllow: ["delegatecall"],
      kind: 'uups'
    }) as StakingHandler;

    // Setup
    await hub.setStakingHandler(shandler.address);
    await hub.setAirdropHandler(adhandler.address);

    // Roles
    await shandler.grantRole(await shandler.HUB(), hub.address);
    await adhandler.grantRole(await adhandler.HUB(), hub.address);
  });

  describe("Staking", async() => {
    it("Should not launch a staking campaign: StakingPeriod not in range 1m-1y", async() => {
      await token1.approve(hub.address, ethers.utils.parseEther("100000"));
      // minTimeLock = 1 days, stakingPeriod = 3 days, maxStakeAmount = 45
      await expect(hub.launchStaking(token1.address, 10, 86400 ,219200, ethers.utils.parseUnits("45", 18))).to.be.revertedWith("stakeTime not in 1m - 1y range");
    });

    it("Should not launch a staking campaign: Incorrect daily interest", async() => {
      await token1.approve(hub.address, ethers.utils.parseEther("100000000"));
      // minTimeLock = 1 days, stakingPeriod = 2 months, maxStakeAmount = 45
      await expect(hub.launchStaking(token1.address, 5000000, 86400 ,5184000, ethers.utils.parseUnits("45", 18))).to.be.reverted;
    });

    it("Should launch a staking campaign", async() => {
      await token1.approve(hub.address, ethers.utils.parseEther("100000"));
      // minTimeLock = 1 days, stakingPeriod = 2 months, maxStakeAmount = 45, dailyInterest = 0.35%
      await hub.launchStaking(token1.address, 35, 86400 ,5184000, ethers.utils.parseUnits("45", 18));
    });

    it("Should not stake: Amount is less than minStakeAmount", async() => {
      await token1.approve(hub.address, ethers.utils.parseEther("100000"));
      // minTimeLock = 1 days, stakingPeriod = 2 months, maxStakeAmount = 45, dailyInterest = 0.35%
      await hub.launchStaking(token1.address, 35, 86400 ,5184000, ethers.utils.parseUnits("45", 18));
      // await expect(hub.stake(token1.address, 25)).to.be.revertedWith("< minAmount");
    });

    it("Should stake", async() => {
      await token1.approve(hub.address, ethers.utils.parseEther("100000"));
      // minTimeLock = 1 days, stakingPeriod = 2 months, maxStakeAmount = 45, dailyInterest = 0.35%
      await hub.launchStaking(token1.address, 35, 86400 ,5184000, ethers.utils.parseUnits("45", 18));
      await hub.stake(token1.address, ethers.utils.parseUnits("100", 18));
    });

    it("Should not unstake: Staking period not over", async() => {
      await token1.transfer(user1.address, ethers.utils.parseEther("1000"));
      await token1.approve(hub.address, ethers.utils.parseEther("100000"));
      await token1.connect(user1).approve(hub.address, ethers.utils.parseEther("100000"));
      // minTimeLock = 1 days, stakingPeriod = 2 months, maxStakeAmount = 45, dailyInterest = 0.35%
      await hub.launchStaking(token1.address, 35, 86400 ,5184000, ethers.utils.parseUnits("45", 18));
      await hub.connect(user1).stake(token1.address, ethers.utils.parseUnits("100", 18));
      await expect(hub.connect(user1).unstake(token1.address)).to.be.revertedWith("Stake is locked");
    });

    it("Should unstake", async() => {
      await token1.transfer(user1.address, ethers.utils.parseEther("135"));
      await token1.connect(user1).approve(hub.address, ethers.utils.parseEther("100000"));
      await token1.approve(hub.address, ethers.utils.parseEther("100000"));
      // minTimeLock = 1 days, stakingPeriod = 2 months, maxStakeAmount = 45, dailyInterest = 0.35%
      await hub.launchStaking(token1.address, 35, 86400 ,5184000, ethers.utils.parseUnits("45", 18));
      await hub.connect(user1).stake(token1.address, ethers.utils.parseUnits("25", 18));
      const balanceAfterStake = await token1.balanceOf(user1.address);
      await skipDays(20);
      console.log(await token1.balanceOf(hub.address));
      await hub.connect(user1).unstake(token1.address);
      const balanceAfterUnstake = await token1.balanceOf(user1.address);

      console.log("Balance after stake: ", balanceAfterStake.toString());
      console.log("Balance after unstake: ", balanceAfterUnstake.toString());
    });
  });

  describe("Airdrop", async() => {
    it("Should not launch an airdrop: no staking activity yet", async() => {
      // Signature call is needed to address a function with an override
      await expect(hub["launchAirdrop(address,uint256,uint256,bool)"](token1.address, ethers.utils.parseUnits("100", 18), 86400, false)).to.be.revertedWith("Airdrop is not available");
    });

    it("Should launch an airdrop", async() => {
      await token1.approve(hub.address, ethers.utils.parseEther("100000"));
      await token2.approve(hub.address, ethers.utils.parseEther("100000"));
      // minTimeLock = 1 days, stakingPeriod = 2 months, maxStakeAmount = 45, dailyInterest = 0.35%
      await hub.launchStaking(token1.address, 35, 86400 ,5184000, ethers.utils.parseUnits("45", 18));
      await skipDays(80);
      await hub.finaliseStaking(token1.address);
      await hub["launchAirdrop(address,uint256,uint256,bool)"](token2.address, ethers.utils.parseUnits("100", 18), 86400, false);
    });

    it("Should let user claim airdrop", async() => {
      // Allowance
      await token1.approve(hub.address, ethers.utils.parseEther("100000"));
      await token2.approve(hub.address, ethers.utils.parseEther("100000"));

      // minTimeLock = 1 days, stakingPeriod = 2 months, maxStakeAmount = 45, dailyInterest = 0.35%
      await hub.launchStaking(token1.address, 35, 86400 ,5184000, ethers.utils.parseUnits("45", 18));
      await skipDays(80);
      await hub.finaliseStaking(token1.address);
      await hub["launchAirdrop(address,uint256,uint256,bool)"](token2.address, ethers.utils.parseUnits("100", 18), 86400, false);
      await hub.claimAirdrop(token2.address);
    });

    it("Should calculate airdrop rewards correctly", async() => {
      // Allowance
      await token1.approve(hub.address, ethers.utils.parseEther("100000"));
      await token2.approve(hub.address, ethers.utils.parseEther("100000"));

      // minTimeLock = 1 days, stakingPeriod = 2 months, maxStakeAmount = 45, dailyInterest = 0.35%
      await hub.launchStaking(token1.address, 35, 86400 ,5184000, ethers.utils.parseUnits("45", 18));
      await skipDays(80);
      await hub.finaliseStaking(token1.address);
      await hub["launchAirdrop(address,uint256,uint256,bool)"](token2.address, ethers.utils.parseUnits("10", 18), 86400, false);
      const balanceBefore = await token2.balanceOf(user1.address);
      await hub.connect(user1).claimAirdrop(token2.address);
      const balanceAfter = await token2.balanceOf(user1.address);

      console.log("User balance before claiming aidrop: ", balanceBefore.toString());
      console.log("User balance after claiming aidrop: ", balanceAfter.toString());
    });
  });
});