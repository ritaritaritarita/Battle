import { deployDeckContract, deployBattleContract, getProvider } from './helpers/contract';
import { PepemonCard, PepemonCardDeck, PepemonBattle } from '../typechain';
import { PepemonFactory } from "../typechain/PepemonFactory";


import DeckArtifact from '../artifacts/contracts/PepemonCardDeck.sol/PepemonCardDeck.json';
import CardArtifact from '../artifacts/contracts/PepemonCard.sol/PepemonCard.json';
import BattleArtifact from '../artifacts/contracts/PepemonBattle.sol/PepemonBattle.json';
import FactoryArtifact from '../contracts/abi/PepemonFactory.json';

import { expect } from 'chai';
import { deployContract, deployMockContract, MockContract } from 'ethereum-waffle';
import { BigNumber } from 'ethers';

const [alice, bob] = getProvider().getWallets();

const battleCardData = [
  {
    battleCardId: 1,
    battleCardType: 0,
    name: 'Pepesaur',
    hp: 450,
    spd: 10,
    inte: 5,
    def: 10,
    atk: 10,
    sAtk: 20,
    sDef: 20
  },
  {
    battleCardId: 2,
    battleCardType: 0,
    name: 'Pepemander',
    hp: 300,
    spd: 20,
    inte: 6,
    def: 8,
    atk: 12,
    sAtk: 24,
    sDef: 16
  }
];

const supportCardData = [
  {
    supportCardId: 1,
    supportCardType: 0,
    name: 'Fast Attack',
    effectOnes: [
      {
        power: 2,
        effectTo: 0,
        effectFor: 0,
        reqCode: 0
      }
    ],
    effectMany: {
      power: 0,
      numTurns: 0,
      effectTo: 0,
      effectFor: 0,
      reqCode: 0
    },
    unstackable: true,
    unresettable: true
  },
  {
    supportCardId: 2,
    supportCardType: 0,
    name: 'Mid Attack',
    effectOnes: [
      {
        power: 3,
        effectTo: 0,
        effectFor: 0,
        reqCode: 0
      }
    ],
    effectMany: {
      power: 0,
      numTurns: 0,
      effectTo: 0,
      effectFor: 0,
      reqCode: 0
    },
    unstackable: true,
    unresettable: true
  }
];

describe('::Battle', async () => {
  let battle: PepemonBattle;
  let bobSignedBattle: PepemonBattle;
  let deck: PepemonCardDeck;
  let bobSignedDeck: PepemonCardDeck;
  let card: PepemonCard;
  let battleCard: PepemonFactory | MockContract;
  let supportCard: PepemonFactory | MockContract;

  const setupCard = async () => {
    await card.addBattleCard({
      battleCardId: 1,
      battleCardType: 0,
      name: 'Pepesaur',
      hp: 450,
      spd: 10,
      inte: 5,
      def: 10,
      atk: 10,
      sAtk: 20,
      sDef: 20
    });
    await card.addBattleCard({
      battleCardId: 2,
      battleCardType: 0,
      name: 'Pepemander',
      hp: 300,
      spd: 20,
      inte: 6,
      def: 8,
      atk: 12,
      sAtk: 24,
      sDef: 16
    });
    await card.addSupportCard({
      supportCardId: 1,
      supportCardType: 0,
      name: 'Fast Attack',
      effectOnes: [
        {
          power: 2,
          effectTo: 0,
          effectFor: 0,
          reqCode: 0
        }
      ],
      effectMany: {
        power: 0,
        numTurns: 0,
        effectTo: 0,
        effectFor: 0,
        reqCode: 0
      },
      unstackable: true,
      unresettable: true
    });
    await card.addSupportCard({
      supportCardId: 2,
      supportCardType: 0,
      name: 'Mid Attack',
      effectOnes: [
        {
          power: 3,
          effectTo: 0,
          effectFor: 0,
          reqCode: 0
        }
      ],
      effectMany: {
        power: 0,
        numTurns: 0,
        effectTo: 0,
        effectFor: 0,
        reqCode: 0
      },
      unstackable: true,
      unresettable: true
    });
    await card.addSupportCard({
      supportCardId: 3,
      supportCardType: 0,
      name: 'Haymaker Strike',
      effectOnes: [
        {
          power: 4,
          effectTo: 0,
          effectFor: 0,
          reqCode: 0
        }
      ],
      effectMany: {
        power: 0,
        numTurns: 0,
        effectTo: 0,
        effectFor: 0,
        reqCode: 0
      },
      unstackable: true,
      unresettable: true
    });
  };

  const setupDeck = async () => {
    const supportCardRequests = [
      {
        supportCardId: 1,
        amount: 30
      },
      {
        supportCardId: 2,
        amount: 30
      }
    ];

    await deck.createDeck();
    await deck.setBattleCardAddress(battleCard.address);
    await deck.setSupportCardAddress(supportCard.address);
    await bobSignedDeck.createDeck();
    // Battle card
    await battleCard.mock.balanceOf.withArgs(alice.address, 1).returns(1);
    await battleCard.mock.balanceOf.withArgs(bob.address, 2).returns(1);
    await battleCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 1, 1, '0x').returns();
    await battleCard.mock.safeTransferFrom.withArgs(bob.address, bobSignedDeck.address, 2, 1, '0x').returns();

    await deck.addBattleCardToDeck(1, 1);
    await bobSignedDeck.addBattleCardToDeck(2, 2);
    // Support Card
    await supportCard.mock.balanceOf.withArgs(alice.address, 1).returns(30);
    await supportCard.mock.balanceOf.withArgs(alice.address, 2).returns(30);
    await supportCard.mock.balanceOf.withArgs(bob.address, 1).returns(25);
    await supportCard.mock.balanceOf.withArgs(bob.address, 2).returns(45);
    await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 1, 30, '0x').returns();
    await supportCard.mock.safeTransferFrom.withArgs(alice.address, deck.address, 2, 30, '0x').returns();
    await supportCard.mock.safeTransferFrom.withArgs(bob.address, bobSignedDeck.address, 1, 25, '0x').returns();
    await supportCard.mock.safeTransferFrom.withArgs(bob.address, bobSignedDeck.address, 2, 45, '0x').returns();

    await deck.addSupportCardsToDeck(1, [
      {
        supportCardId: 1,
        amount: 30
      },
      {
        supportCardId: 2,
        amount: 30
      }
    ]);
    await bobSignedDeck.addSupportCardsToDeck(2, [
      {
        supportCardId: 1,
        amount: 25
      },
      {
        supportCardId: 2,
        amount: 45
      }
    ]);
  };

  beforeEach(async () => {
    deck = (await deployContract(alice, DeckArtifact)) as PepemonCardDeck;
    bobSignedDeck = deck.connect(bob);
    card = (await deployContract(alice, CardArtifact)) as PepemonCard;
    battle = (await deployContract(alice, BattleArtifact, [card.address, deck.address])) as PepemonBattle;
    bobSignedBattle = battle.connect(bob);
    battleCard = await deployMockContract(alice, FactoryArtifact);
    supportCard = await deployMockContract(alice, FactoryArtifact);

    // card
    await setupCard();
    // deck
    await setupDeck();
  });

  // describe('#createBattle', async () => {
  //   it('Should create battle', async () => {
  //     await battle.createBattle(alice.address, bob.address);
  //     await battle.battles(1).then((battle: any) => {
  //       expect(battle['battleId']).to.eq(1);
  //       expect(battle['p1']).to.eq(alice.address);
  //       expect(battle['p2']).to.eq(bob.address);
  //     });
  //   });
  //   describe('reverts if', async () => {
  //     it('non-admin create battle', async () => {
  //       await expect(bobSignedBattle.createBattle(alice.address, bob.address)).to.revertedWith('revert Ownable: caller is not the owner');
  //     });
  //     it('battle yourself', async () => {
  //       await expect(battle.createBattle(alice.address, alice.address)).to.revertedWith('revert PepemonBattle: No Battle yourself');
  //     });
  //   });
  // });

  describe('#fight', async () => {
    beforeEach(async () => {
      await battle.createBattle(alice.address, bob.address);
    });
    it('should shuffle players\' decks', async () => {
      let str = '';
      // Shuffle each player's decks
      await battle._shufflePlayerDeck(1);
      await battle.getBattleP1SupportCards(1).then((p1SupportCards: any) => {
        p1SupportCards.forEach((item: any) => {
          str += item.toString() + ' ';
        });
        console.log('Player 1 supportCards:', str);
      });
      str = '';
      await battle.getBattleP2SupportCards(1).then((p2SupportCards: any) => {
        p2SupportCards.forEach((item: any) => {
          str += item.toString() + ' ';
        });
        console.log('Player 2 supportCards:', str);
      });
      // Make the first turn
      await battle._makeNewTurn(1);

    });
  });
});
