import { ethers, upgrades } from 'hardhat';
import { expect } from 'chai';
import { Signer, BigNumber } from 'ethers';
import { SimpleStakingHandler__factory, SimpleAirdropHandler__factory, SimpleAirdropHandler, SimpleStakingHandler, RukiaToken__factory, RukiaToken, CaminoHub__factory, CaminoHub} from '../typechain-types';

describe('CaminoHub', () => {
  let owner: Signer;
  let alice: Signer;
  let bob: Signer;

  let Token: RukiaToken__factory;
  let StakingHandler: SimpleStakingHandler__factory;
  let AirdropHandler: SimpleAirdropHandler__factory;
  let CaminoHub: CaminoHub__factory;

  let token: RukiaToken;
  let stakingHandler: SimpleStakingHandler;
  let airdropHandler: SimpleAirdropHandler;
  let caminoHub: CaminoHub;

  before(async () => {
    [owner, alice, bob] = await ethers.getSigners();

    Token = (await ethers.getContractFactory('TestERC20')) as TestERC20__factory;
    StakingHandler = (await ethers.getContractFactory('SimpleStakingHandler')) as SimpleStakingHandler__factory;
    AirdropHandler = (await ethers.getContractFactory('SimpleAirdropHandler')) as SimpleAirdropHandler__factory;
    CaminoHub = (await ethers.getContractFactory('CaminoHub')) as CaminoHub__factory;

    token = await Token.connect(owner).deploy(initialSupply, 'TestToken', 'TEST');
    stakingHandler = await StakingHandler.connect(owner).deploy();
    airdropHandler = await AirdropHandler.connect(owner).deploy();
    caminoHub = await CaminoHub.connect(owner).deploy(stakingHandler.address, airdropHandler.address);
  });
  

  describe('CaminoHub', () => {
    it('Should be able to launch a new staking', async () => {
      const duration = 1000;
      const stakedToken = tokenInstance.address;

      await tokenInstance.connect(alice).approve(caminoHubInstance.address, stakeAmount);
      await expect(caminoHubInstance.connect(alice).launchStaking(stakeAmount, duration, stakedToken)).to.emit(stakingHandlerInstance, 'StakingLaunched');

      const stakings = await stakingHandlerInstance.getStakings(alice.getAddress());
      expect(stakings).to.have.lengthOf(1);
      expect(stakings[0].amount).to.equal(stakeAmount);
      expect(stakings[0].duration).to.equal(duration);
      expect(stakings[0].stakedToken).to.equal(stakedToken);
    });

    it('Should be able to launch a new airdrop
