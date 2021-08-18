import {getProvider} from './helpers/contract';
import RNGArtifact from '../artifacts/contracts/RandomNumberGenerator.sol/RandomNumberGenerator.json';
import {RandomNumberGenerator} from '../typechain';
import {expect} from 'chai';
import {deployContract} from 'ethereum-waffle';
import { Contract } from 'ethers';

const [alice, bob] = getProvider().getWallets();

describe('Chainlink Random Numnber', () => {
  let randomNumberContract: RandomNumberGenerator;

    beforeEach(async () => {
        randomNumberContract = (await deployContract(alice, RNGArtifact)) as RandomNumberGenerator;
    });

    describe('Get Random Number', async () => {
        it('should get random number from chainLink', async () => {
        await randomNumberContract.getRandomNumber().then((randomNumber: any) => {
            console.log("Random number: ", randomNumber);
        })
    });

});
});
