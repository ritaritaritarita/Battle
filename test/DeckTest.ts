import { deployDeckContract, getProvider } from './helpers/contract';
import { PepemonCardDeck } from '../typechain';
import { PepemonFactory } from '../typechain';
import { RandomNumberGenerator } from '../typechain';
import PepemonFactoryArtifact from '../contracts/abi/PepemonFactory.json';
import RandomNumberGeneratorArtifact from '../artifacts/contracts/RandomNumberGenerator.sol/RandomNumberGenerator.json';

import { expect } from 'chai';
import { deployMockContract, MockContract } from 'ethereum-waffle';
import { BigNumber } from 'ethers';

const [alice, bob] = getProvider().getWallets();

describe('::Deck', () => {
  let deck: PepemonCardDeck;
  let bobSignedDeck: PepemonCardDeck;
  let battleCard: PepemonFactory | MockContract;
  let supportCard: PepemonFactory | MockContract;
  let randomNumberGenerator: RandomNumberGenerator | MockContract;

  beforeEach(async () => {
    deck = await deployDeckContract(alice);
    bobSignedDeck = deck.connect(bob);
    battleCard = await deployMockContract(alice, PepemonFactoryArtifact);
    supportCard = await deployMockContract(alice, PepemonFactoryArtifact);
    randomNumberGenerator = await deployMockContract(alice, RandomNumberGeneratorArtifact.abi);

    await deck.setBattleCardAddress(battleCard.address);
    await deck.setSupportCardAddress(supportCard.address);
    await deck.setRandomNumberGenerator(randomNumberGenerator.address);

    await battleCard.mock.balanceOf.withArgs(alice.address, 1).returns(1);
  });

  describe('#Deck', async () => {
    it('Should allow a deck to be created', async () => {
      await deck.createDeck();

      await deck.ownerOf(1).then((ownerAddress: string) => {
        expect(ownerAddress).to.eq(alice.address);
      });
    });
  });

  describe('#Battle card', async () => {
    beforeEach(async () => {
      await deck.createDeck();
      await battleCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 1, 1, '0x').returns();
      await battleCard.mock.balanceOf.withArgs(alice.address, 1).returns(1);
    });

    it('Should allow adding a Battle Card to the deck', async () => {
      await deck.addBattleCardToDeck(1, 1);
      await deck.decks(1).then((deck: any) => {
        expect(deck['battleCardId']).to.eq(1);
      });
    });

    it('Should return the previous battle card if one has already been supplied', async () => {
      // Mock deposit transfer
      await battleCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 1, 1, '0x').returns();
      await battleCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 2, 1, '0x').returns();

      // Mock balance
      await battleCard.mock.balanceOf.withArgs(alice.address, 1).returns(1);
      await battleCard.mock.balanceOf.withArgs(alice.address, 2).returns(1);

      // Mock withdrawal transfer
      await battleCard.mock.safeTransferFrom.withArgs(deck.address, alice.address, 1, 1, '0x').returns();

      // Add cards
      await deck.addBattleCardToDeck(1, 1);
      await deck.addBattleCardToDeck(1, 2);

      expect(await deck.getBattleCardInDeck(1)).to.eq(2);
    });

    it('Should allow removing a Battle Card from the deck', async () => {
      await battleCard.mock.safeTransferFrom.withArgs(deck.address, alice.address, 1, 1, '0x').returns();

      await deck.addBattleCardToDeck(1, 1);

      await deck.removeBattleCardFromDeck(1);

      await deck.getBattleCardInDeck(1).then((battleCardId: BigNumber) => {
        expect(battleCardId).to.eq(0);
      });
    });

    describe('Permissions', async () => {
      it("Should prevent adding cards you don't have", async () => {
        await battleCard.mock.balanceOf.withArgs(bob.address, 1).returns(0);
        await expect(bobSignedDeck.addBattleCardToDeck(1, 1)).to.be.revertedWith(
          "revert PepemonCardDeck: Don't own battle card"
        );
      });

      it("Should prevent removing a battle card from a deck which you don't own", async () => {
        await expect(bobSignedDeck.removeBattleCardFromDeck(1)).to.be.revertedWith(
          'revert PepemonCardDeck: Not your deck'
        );
      });
    });
  });

  describe('#Support cards', async () => {
    beforeEach(async () => {
      await deck.createDeck();
      await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 20, 2, '0x').returns();
      await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 12, 1, '0x').returns();

      await supportCard.mock.balanceOf.withArgs(alice.address, 20).returns(8);
      await supportCard.mock.balanceOf.withArgs(alice.address, 12).returns(1);
    });

    it('Should allow support cards to be added to the deck', async () => {
      await deck.addSupportCardsToDeck(1, [
        { supportCardId: 20, amount: 2 },
        { supportCardId: 12, amount: 1 },
      ]);

      await deck.decks(1).then((deck: any) => {
        expect(deck['supportCardCount']).to.eq(3);
      });

      await deck.getCardTypesInDeck(1).then((cardTypes: BigNumber[]) => {
        expect(cardTypes.length).to.eq(2);
        expect(cardTypes[0]).to.eq(20);
        expect(cardTypes[1]).to.eq(12);
      });

      expect(await deck.getCountOfCardTypeInDeck(1, 20)).to.eq(2);
      expect(await deck.getCountOfCardTypeInDeck(1, 12)).to.eq(1);
    });

    it('Should allow support cards to be removed from the deck', async () => {
      await supportCard.mock.balanceOf.withArgs(alice.address, 20).returns(50);
      await supportCard.mock.balanceOf.withArgs(alice.address, 12).returns(30);

      await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 20, 45, '0x').returns();
      await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 12, 10, '0x').returns();
      await supportCard.mock.safeTransferFrom.withArgs(deck.address, alice.address, 20, 2, '0x').returns();

      await deck.addSupportCardsToDeck(1, [
        { supportCardId: 20, amount: 45 },
        { supportCardId: 12, amount: 10 },
      ]);

      await deck.removeSupportCardsFromDeck(1, [
        {
          supportCardId: 20,
          amount: 2,
        },
      ]);

      await deck.decks(1).then((deck: any) => {
        expect(deck['supportCardCount']).to.eq(53);
      });

      expect(await deck.getCountOfCardTypeInDeck(1, 20)).to.eq(43);
    });

    it('Should allow getting all support cards from deck', async () => {
      await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 20, 2, '0x').returns();
      await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 12, 2, '0x').returns();

      await supportCard.mock.balanceOf.withArgs(alice.address, 20).returns(8);
      await supportCard.mock.balanceOf.withArgs(alice.address, 12).returns(2);

      await deck.addSupportCardsToDeck(1, [
        { supportCardId: 20, amount: 2 },
        { supportCardId: 12, amount: 2 },
      ]);
      await deck.getAllSupportCardsInDeck(1).then((supportCards: BigNumber[]) => {
        expect(supportCards.length).to.eq(4);

        for (let i = 0; i < supportCards.length; i++) {
          console.log(supportCards[i].toString());
        }
      });
    });

    it('Should shuffle deck in random order', async () => {
      await supportCard.mock.balanceOf.withArgs(alice.address, 20).returns(23);
      await supportCard.mock.balanceOf.withArgs(alice.address, 12).returns(15);
      await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 20, 23, '0x').returns();
      await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 12, 15, '0x').returns();

      await randomNumberGenerator.mock.getRandomNumber.withArgs().returns(4000);

      await deck.addSupportCardsToDeck(1, [
        { supportCardId: 20, amount: 23 },
        { supportCardId: 12, amount: 15 },
      ]);

      // terrible
      await deck.shuffleDeck(1).then((supportCards: BigNumber[]) => {
        expect(supportCards.length).to.eq(38);

        expect(supportCards[0]).to.eq(BigNumber.from(20), '0');
        expect(supportCards[1]).to.eq(BigNumber.from(20), '1');
        expect(supportCards[2]).to.eq(BigNumber.from(20), '2');
        expect(supportCards[3]).to.eq(BigNumber.from(20), '3');
        expect(supportCards[4]).to.eq(BigNumber.from(12), '4');
        expect(supportCards[5]).to.eq(BigNumber.from(20), '5');
        expect(supportCards[6]).to.eq(BigNumber.from(20), '6');
        expect(supportCards[7]).to.eq(BigNumber.from(20), '7');
        expect(supportCards[8]).to.eq(BigNumber.from(20), '8');
        expect(supportCards[9]).to.eq(BigNumber.from(12), '9');
        expect(supportCards[10]).to.eq(BigNumber.from(12), '10');
        expect(supportCards[11]).to.eq(BigNumber.from(20), '11');
        expect(supportCards[12]).to.eq(BigNumber.from(20), '12');
        expect(supportCards[13]).to.eq(BigNumber.from(20), '13');
        expect(supportCards[14]).to.eq(BigNumber.from(12), '14');
        expect(supportCards[15]).to.eq(BigNumber.from(20), '15');
        expect(supportCards[16]).to.eq(BigNumber.from(20), '16');
        expect(supportCards[17]).to.eq(BigNumber.from(12), '17');
        expect(supportCards[18]).to.eq(BigNumber.from(20), '18');
        expect(supportCards[19]).to.eq(BigNumber.from(12), '19');
        expect(supportCards[20]).to.eq(BigNumber.from(12), '20');
        expect(supportCards[21]).to.eq(BigNumber.from(20), '21');
        expect(supportCards[22]).to.eq(BigNumber.from(20), '22');
        expect(supportCards[23]).to.eq(BigNumber.from(12), '23');
        expect(supportCards[24]).to.eq(BigNumber.from(20), '24');
        expect(supportCards[25]).to.eq(BigNumber.from(20), '25');
        expect(supportCards[26]).to.eq(BigNumber.from(20), '26');
        expect(supportCards[27]).to.eq(BigNumber.from(12), '27');
        expect(supportCards[28]).to.eq(BigNumber.from(12), '28');
        expect(supportCards[29]).to.eq(BigNumber.from(12), '29');
        expect(supportCards[30]).to.eq(BigNumber.from(20), '30');
        expect(supportCards[31]).to.eq(BigNumber.from(20), '31');
        expect(supportCards[32]).to.eq(BigNumber.from(20), '32');
        expect(supportCards[33]).to.eq(BigNumber.from(20), '33');
        expect(supportCards[34]).to.eq(BigNumber.from(12), '34');
        expect(supportCards[35]).to.eq(BigNumber.from(12), '35');
        expect(supportCards[36]).to.eq(BigNumber.from(12), '36');
        expect(supportCards[37]).to.equal(BigNumber.from(12), '37');
      });
    });

    describe('reverts if', async () => {
      it('support card count is lower than min number', async () => {
        await supportCard.mock.balanceOf.withArgs(alice.address, 20).returns(50);
        await supportCard.mock.balanceOf.withArgs(alice.address, 12).returns(30);

        await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 20, 45, '0x').returns();
        await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 12, 10, '0x').returns();
        await supportCard.mock.safeTransferFrom.withArgs(deck.address, alice.address, 20, 30, '0x').returns();

        await deck.addSupportCardsToDeck(1, [
          { supportCardId: 20, amount: 45 },
          { supportCardId: 12, amount: 10 },
        ]);

        await expect(
          deck.removeSupportCardsFromDeck(1, [
            {
              supportCardId: 20,
              amount: 30,
            },
          ])
        ).to.be.revertedWith('PepemonCardDeck: Deck underflow');
      });

      it('support card count is greater than max number', async () => {
        await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 20, 20, '0x').returns();
        await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 12, 60, '0x').returns();

        await supportCard.mock.balanceOf.withArgs(alice.address, 20).returns(20);
        await supportCard.mock.balanceOf.withArgs(alice.address, 12).returns(60);

        await expect(
          deck.addSupportCardsToDeck(1, [
            {
              supportCardId: 20,
              amount: 20,
            },
            {
              supportCardId: 12,
              amount: 55,
            },
          ])
        ).to.be.revertedWith('revert PepemonCardDeck: Deck overflow');
      });
    });
  });

  describe('#Permissions', async () => {
    it('Should prevent anyone but the owner from setting the Battle Card address', async () => {
      await expect(bobSignedDeck.setBattleCardAddress(bob.address)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
    });

    it('Should prevent anyone but the owner from setting the Support Card address', async () => {
      await expect(bobSignedDeck.setSupportCardAddress(bob.address)).to.be.revertedWith(
        'Ownable: caller is not the owner'
      );
    });
  });
});
