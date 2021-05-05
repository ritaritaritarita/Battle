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

describe('Battle', () => {
  let battle: PepemonBattle;
  let deck: PepemonCardDeck;
  let bobSignedDeck: PepemonCardDeck;
  let card: PepemonCard;
  let battleCard: PepemonFactory | MockContract;
  let supportCard: PepemonFactory | MockContract;

  beforeEach(async () => {
    deck = (await deployContract(alice, DeckArtifact)) as PepemonCardDeck;
    bobSignedDeck = deck.connect(bob);
    card = (await deployContract(alice, CardArtifact)) as PepemonCard;
    battle = (await deployContract(alice, BattleArtifact, [card.address, deck.address])) as PepemonBattle;
    // console.log(battle.constructor._json.deployedBytecode.length);
    battleCard = await deployMockContract(alice, FactoryArtifact);
    supportCard = await deployMockContract(alice, FactoryArtifact);

    // card
    // await card.addBattleCard({
    //   battleCardId: 1,
    //   battleCardType: 0,
    //   name: 'Pepesaur',
    //   hp: 450,
    //   spd: 10,
    //   inte: 5,
    //   def: 10,
    //   atk: 10,
    //   sAtk: 20,
    //   sDef: 20
    // });
    // await card.addBattleCard({
    //   battleCardId: 2,
    //   battleCardType: 0,
    //   name: 'Pepemander',
    //   hp: 300,
    //   spd: 20,
    //   inte: 6,
    //   def: 8,
    //   atk: 12,
    //   sAtk: 24,
    //   sDef: 16
    // });
    // await card.addSupportCard({
    //   supportCardId: 1,
    //   supportCardType: 0,
    //   name: 'Fast Attack',
    //   effectOnes: [
    //     {
    //       power: 2,
    //       effectTo: 0,
    //       effectFor: 0,
    //       reqCode: 0
    //     }
    //   ],
    //   effectMany: {
    //     power: 0,
    //     numTurns: 0,
    //     effectTo: 0,
    //     effectFor: 0,
    //     reqCode: 0
    //   },
    //   unstackable: true,
    //   unresettable: true
    // });
    // await card.addSupportCard({
    //   supportCardId: 2,
    //   supportCardType: 0,
    //   name: 'Mid Attack',
    //   effectOnes: [
    //     {
    //       power: 3,
    //       effectTo: 0,
    //       effectFor: 0,
    //       reqCode: 0
    //     }
    //   ],
    //   effectMany: {
    //     power: 0,
    //     numTurns: 0,
    //     effectTo: 0,
    //     effectFor: 0,
    //     reqCode: 0
    //   },
    //   unstackable: true,
    //   unresettable: true
    // });
    // deck
    // await deck.createDeck();
    // await deck.addBattleCardToDeck(1, 1);
  });

  it('Should allow a battle to be created', async () => {

    // await battle.createBattle(alice.address, bob.address);
    // await battle.battles(1).then((battle: any) => {
    //   expect(battle['battleId']).to.eq(1);
    //   expect(battle['p1']).to.eq(alice.address);
    //   expect(battle['p2']).to.eq(bob.address);
    // });
    // battle.addBattleCard({
    //   battleCardId: 2,
    //   battleType: 1,
    //   hp: 800,
    //   spd: 10,
    //   inte: 7,
    //   def: 24,
    //   atk: 10,
    //   sAtk: 40,
    //   sDef: 24
    // });
  });

  it('Should allow a battle to be started', async () => {
    // await battle.createBattle(alice.address, bob.address);
    // await battle.startBattle(1);
  });
});
