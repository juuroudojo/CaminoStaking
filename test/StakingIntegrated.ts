import { ethers, upgrades } from 'hardhat';
import { expect } from 'chai';
import { Signer, BigNumber } from 'ethers';
import { SimpleStakingHandler__factory, SimpleAirdropHandler__factory, SimpleAirdropHandler, SimpleStakingHandler, RukiaToken__factory, RukiaToken, CaminoHub__factory, CaminoHub} from '../typechain-types';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

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

  })

});