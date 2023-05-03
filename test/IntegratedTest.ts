import { ethers, network } from 'hardhat';
import { expect } from 'chai';
import { BigNumber } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

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
  let flightManager: FlightManager;
  let ticketPurchase: TicketPurchase;
  let ticketManager: TicketManager;
  let refundHandler: RefundHandler;
  let tokenDealer: TokenDealer;
  let tokenDealerM: SignerWithAddress;
  let mockToken: MockToken;
  let boardingValidator: BoardingValidator;
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

    let mockTokenFactory = await ethers.getContractFactory('MockToken');
    mockToken = await mockTokenFactory.deploy('Mock Token', 'MOCK', ethers.utils.parseEther("50")) as MockToken;

    // Instance of mock token to emulate calls.
    mockTokenM = await getImpersonatedSigner(mockToken.address);

    

  });

  describe("Ticket Purchase", async() => {

  });

  describe("Validating the tickets", async() => {
    it("Should not validate if hasn't checked in", async() => {
    });
  });
});