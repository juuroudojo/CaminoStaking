import { ethers, upgrades } from 'hardhat';
import { expect } from 'chai';
import { Signer, BigNumber } from 'ethers';
import { SimpleStakingHandler__factory, SimpleAirdropHandler__factory, SimpleAirdropHandler, SimpleStakingHandler, RukiaToken__factory, RukiaToken, CaminoHub__factory, CaminoHub} from '../typechain-types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

async function skipDays(days: number) {
  ethers.provider.send("evm_increaseTime", [days * 86400]);
  ethers.provider.send("evm_mine", []);
}

describe('CaminoHub', () => {
  let mugen: SignerWithAddress;
  let jin: SignerWithAddress;
  let fuu: SignerWithAddress;

  let Token: RukiaToken__factory;
  let StakingHandler: SimpleStakingHandler__factory;
  let AirdropHandler: SimpleAirdropHandler__factory;
  let CaminoHub: CaminoHub__factory;

  let token: RukiaToken;
  let stakingHandler: SimpleStakingHandler;
  let airdropHandler: SimpleAirdropHandler;
  let caminoHub: CaminoHub;

  before(async () => {
    [mugen, jin, fuu] = await ethers.getSigners();

    Token = (await ethers.getContractFactory('TestERC20')) as RukiaToken__factory;
    StakingHandler = (await ethers.getContractFactory('SimpleStakingHandler')) as SimpleStakingHandler__factory;
    AirdropHandler = (await ethers.getContractFactory('SimpleAirdropHandler')) as SimpleAirdropHandler__factory;
    CaminoHub = (await ethers.getContractFactory('CaminoHub')) as CaminoHub__factory;

    token = await Token.connect(mugen).deploy(ethers.utils.parseUnits("100", 18));

    caminoHub = await upgrades.deployProxy(CaminoHub,
      [],
      {initializer: 'initialize', kind: 'uups'}
      ) as CaminoHub;
  
    stakingHandler = await upgrades.deployProxy(StakingHandler,
      [caminoHub.address],
      {initializer: 'initialize', kind: 'uups'}
      ) as SimpleStakingHandler;

    stakingHandler = await StakingHandler.connect(mugen).deploy();
    airdropHandler = await AirdropHandler.connect(mugen).deploy();
  });
  

  describe('CaminoHub', () => {
    it('Should be able to launch a new staking', async () => {
      const duration = 1000;

      await token.transfer(jin.address, ethers.utils.parseUnits("100", 18));
      await token.connect(jin).approve(caminoHub.address, ethers.utils.parseUnits("100", 18));
      await expect(caminoHub.connect(jin).launchStaking(token.address, 1000, 200000, ethers.utils.parseEther("30"), duration)).to.emit(stakingHandler, 'StakingLaunched');

    });

    it('Should be able to launch a new airdrop', async () => {
      await token.transfer(fuu.address, ethers.utils.parseUnits("100", 18));
      await token.connect(fuu).approve(caminoHub.address, ethers.utils.parseUnits("100", 18));
      await expect(caminoHub.connect(fuu).launchAirdrop(token.address, 1000, 200000, ethers.utils.parseEther("30"))).to.emit(airdropHandler, 'AirdropLaunched');
    });

    it('Should be able to stake', async () => {
      await token.transfer(jin.address, ethers.utils.parseUnits("100", 18));
      await token.connect(jin).approve(stakingHandler.address, ethers.utils.parseUnits("100", 18));
      await expect(stakingHandler.connect(jin).stake(ethers.utils.parseUnits("100", 18))).to.emit(stakingHandler, 'Staked');
    });

    it('Should be able to unstake', async () => {
      await token.transfer(jin.address, ethers.utils.parseUnits("100", 18));
      await token.connect(jin).approve(stakingHandler.address, ethers.utils.parseUnits("100", 18));
      await stakingHandler.connect(jin).stake(ethers.utils.parseUnits("100", 18));
      await expect(stakingHandler.connect(jin).unstake(ethers.utils.parseUnits("100", 18))).to.emit(stakingHandler, 'Unstaked');
    })

    it('Should be able to claim rewards', async () => {
      await token.transfer(jin.address, ethers.utils.parseUnits("100", 18));
      await token.connect(jin).approve(stakingHandler.address, ethers.utils.parseUnits("100", 18));
      await stakingHandler.connect(jin).stake(ethers.utils.parseUnits("100", 18));
      await skipDays(1000);
      await expect(stakingHandler.connect(jin).claimRewards()).to.emit(stakingHandler, 'RewardsClaimed');
    })

    it('Should be able to claim airdrop', async () => {
      await token.transfer(fuu.address, ethers.utils.parseUnits("100", 18));
      await token.connect(fuu).approve(airdropHandler.address, ethers.utils.parseUnits("100", 18));
      await airdropHandler.connect(fuu).claimAirdrop();
      await expect(airdropHandler.connect(fuu).claimAirdrop()).to.emit(airdropHandler, 'AirdropClaimed');
    });

    it("Should not be able to launch a new staking if the staking is already launched", async () => {
      const duration = 1000;

      await token.transfer(jin.address, ethers.utils.parseUnits("100", 18));
      await token.connect(jin).approve(caminoHub.address, ethers.utils.parseUnits("100", 18));
      await expect(caminoHub.connect(jin).launchStaking(token.address, 1000, 200000, ethers.utils.parseEther("30"), duration)).to.be.revertedWith("Staking already launched");
    })

    it("Should not be able to launch a new airdrop if the airdrop is already launched", async () => {
      await token.transfer(fuu.address, ethers.utils.parseUnits("100", 18));
      await token.connect(fuu).approve(caminoHub.address, ethers.utils.parseUnits("100", 18));
      await expect(caminoHub.connect(fuu).launchAirdrop(token.address, 1000, 200000, ethers.utils.parseEther("30"))).to.be.revertedWith("Airdrop already launched");
    })

    it("Should not be able to stake if the staking is not launched", async () => {
      await token.transfer(jin.address, ethers.utils.parseUnits("100", 18));
      await token.connect(jin).approve(stakingHandler.address, ethers.utils.parseUnits("100", 18));
      await expect(stakingHandler.connect(jin).stake(ethers.utils.parseUnits("100", 18))).to.be.revertedWith("Staking not launched");
    })

    it("Should not be able to unstake if the staking is not launched", async () => {
      await token.transfer(jin.address, ethers.utils.parseUnits("100", 18));
      await token.connect(jin).approve(stakingHandler.address, ethers.utils.parseUnits("100", 18));
      await expect(stakingHandler.connect(jin).unstake(ethers.utils.parseUnits("100", 18))).to.be.revertedWith("Staking not launched");
    });

    it("Should not allow user to claim Airdrop if he hasn't staked", async () => {
      await token.transfer(fuu.address, ethers.utils.parseUnits("100", 18));
      await token.connect(fuu).approve(airdropHandler.address, ethers.utils.parseUnits("100", 18));
      await expect(airdropHandler.connect(fuu).claimAirdrop()).to.be.revertedWith("You haven't staked yet");
    });
  })

});