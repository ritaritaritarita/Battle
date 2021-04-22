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
    battleCard = await deployMockContract(alice, FactoryArtifact);
    supportCard = await deployMockContract(alice, FactoryArtifact);

    // card
    await card.addBattleCard({
      battleCardId: 1,
      battleType: 1,
      hp: 400,
      spd: 5,
      inte: 6,
      def: 12,
      atk: 5,
      sAtk: 20,
      sDef: 12
    });
    await card.addBattleCard({
      battleCardId: 2,
      battleType: 1,
      hp: 800,
      spd: 10,
      inte: 7,
      def: 24,
      atk: 10,
      sAtk: 40,
      sDef: 24
    });
    await card.addSupportCard({
      supportCardId: 1,
      supportType: 1,
      modifierTypeCurrentTurn: 1,
      modifierValueCurrentTurn: 1,
      modifierTypeNextTurns: 1,
      modifierValueNextTurns: 1,
      modifierNumberOfNextTurns: 1,
      requirementCode: 1
    });
    await card.addSupportCard({
      supportCardId: 2,
      supportType: 2,
      modifierTypeCurrentTurn: 2,
      modifierValueCurrentTurn: 2,
      modifierTypeNextTurns: 2,
      modifierValueNextTurns: 2,
      modifierNumberOfNextTurns: 2,
      requirementCode: 2
    });
    // deck
    await deck.createDeck();
    await deck.addBattleCardToDeck(1, 1);

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
