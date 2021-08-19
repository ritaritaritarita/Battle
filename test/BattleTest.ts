import { getProvider } from './helpers/contract';
import { PepemonBattle, PepemonCardOracle, PepemonCardDeck, RandomNumberGenerator } from '../typechain';

import DeckArtifact from '../artifacts/contracts/PepemonCardDeck.sol/PepemonCardDeck.json';
import PepemonCardOracleArtifact from '../artifacts/contracts/PepemonCardOracle.sol/PepemonCardOracle.json';
import BattleArtifact from '../artifacts/contracts/PepemonBattle.sol/PepemonBattle.json';
import RNGArtifact from '../artifacts/contracts/RandomNumberGenerator.sol/RandomNumberGenerator.json';

import { deployContract, deployMockContract, MockContract } from 'ethereum-waffle';
import { BigNumber } from 'ethers';

const [alice, bob] = getProvider().getWallets();

const EffectTo = ['ATTACK', 'STRONG_ATTACK', 'DEFENSE', 'STRONG_DEFENSE', 'SPEED', 'INTELLIGENCE'];
const EffectFor = ['ME', 'ENEMY'];
const Attacker = ['PLAYER_ONE', 'PLAYER_TWO'];
const TurnHalves = ['FIRST_HALF', 'SECOND_HALF'];

describe('::Battle', async () => {
  let battleContract: PepemonBattle;
  let pepemonDeckOracle: PepemonCardDeck | MockContract;
  let pepemonCardOracle: PepemonCardOracle | MockContract;
  let rng: RandomNumberGenerator | MockContract;

  beforeEach(async () => {
    pepemonDeckOracle = await deployMockContract(alice, DeckArtifact.abi);
    pepemonCardOracle = await deployMockContract(alice, PepemonCardOracleArtifact.abi);
    rng = await deployMockContract(alice, RNGArtifact.abi);

    battleContract = (await deployContract(alice, BattleArtifact, [
      pepemonCardOracle.address,
      pepemonDeckOracle.address,
      rng.address,
    ])) as PepemonBattle;

    await setupCardOracle();
    await setupDeckOracle();
    await setupRNGOracle();
  });

  const setupCardOracle = async () => {
    await pepemonCardOracle.mock.getBattleCardById.withArgs(1).returns({
      battleCardId: BigNumber.from(1),
      battleCardType: 0,
      name: 'Pepesaur',
      hp: BigNumber.from(50),
      // hp: BigNumber.from(450),
      spd: BigNumber.from(10),
      inte: BigNumber.from(5),
      def: BigNumber.from(10),
      atk: BigNumber.from(10),
      sAtk: BigNumber.from(20),
      sDef: BigNumber.from(20),
    });

    await pepemonCardOracle.mock.getBattleCardById.withArgs(2).returns({
      battleCardId: BigNumber.from(2),
      battleCardType: 0,
      name: 'Pepemander',
      hp: BigNumber.from(30),
      // hp: BigNumber.from(300),
      spd: BigNumber.from(20),
      inte: BigNumber.from(6),
      def: BigNumber.from(8),
      atk: BigNumber.from(12),
      sAtk: BigNumber.from(24),
      sDef: BigNumber.from(16),
    });

    await pepemonCardOracle.mock.getSupportCardById.withArgs(1).returns({
      supportCardId: BigNumber.from(1),
      supportCardType: 0,
      name: 'Fast Attack',
      effectOnes: [
        {
          power: BigNumber.from(2),
          effectTo: 0,
          effectFor: 0,
          reqCode: BigNumber.from(0),
        },
      ],
      effectMany: {
        power: BigNumber.from(0),
        numTurns: BigNumber.from(0),
        effectTo: 0,
        effectFor: 0,
        reqCode: BigNumber.from(0),
      },
      unstackable: true,
      unresettable: true,
    });

    await pepemonCardOracle.mock.getSupportCardById.withArgs(2).returns({
      supportCardId: BigNumber.from(2),
      supportCardType: 0,
      name: 'Mid Attack',
      effectOnes: [
        {
          power: BigNumber.from(3),
          effectTo: 0,
          effectFor: 0,
          reqCode: BigNumber.from(0),
        },
      ],
      effectMany: {
        power: BigNumber.from(0),
        numTurns: BigNumber.from(0),
        effectTo: 0,
        effectFor: 0,
        reqCode: BigNumber.from(0),
      },
      unstackable: true,
      unresettable: true,
    });

    await pepemonCardOracle.mock.getSupportCardById.withArgs(3).returns({
      supportCardId: BigNumber.from(3),
      supportCardType: 0,
      name: 'Haymaker Strike',
      effectOnes: [
        {
          power: BigNumber.from(4),
          effectTo: 0,
          effectFor: 0,
          reqCode: BigNumber.from(0),
        },
      ],
      effectMany: {
        power: BigNumber.from(0),
        numTurns: BigNumber.from(0),
        effectTo: 0,
        effectFor: 0,
        reqCode: BigNumber.from(0),
      },
      unstackable: true,
      unresettable: true,
    });
  };

  const setupDeckOracle = async () => {
    // Deck 1
    await pepemonDeckOracle.mock.shuffleDeck
      .withArgs(1)
      .returns([
        1, 3, 1, 2, 3, 1, 3, 2, 1, 3, 1, 2, 3, 1, 3, 2, 1, 3, 1, 2, 1, 3, 1, 2, 3, 1, 3, 2, 1, 3, 1, 2, 3, 1, 3, 2, 1,
        3, 1, 2, 1, 3, 1, 2, 3, 1, 3, 2, 1, 3,
      ]);
    await pepemonDeckOracle.mock.decks.withArgs(1).returns(BigNumber.from(1), BigNumber.from(50));
    await pepemonDeckOracle.mock.getSupportCardCountInDeck.withArgs(1).returns(50);
    // Deck 2
    await pepemonDeckOracle.mock.shuffleDeck
      .withArgs(2)
      .returns([
        3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1,
        2, 3, 1, 3, 1, 2, 3, 1,
      ]);
    await pepemonDeckOracle.mock.decks.withArgs(2).returns(BigNumber.from(2), BigNumber.from(45));
    await pepemonDeckOracle.mock.getSupportCardCountInDeck.withArgs(2).returns(45);
  };

  const setupRNGOracle = async () => {
    await rng.mock.getRandomNumber.returns(10);
  };

  const logBattle = (battle: any) => {
    console.log('Battle:');
    console.log('-battleId:', battle.battleId.toString());
    console.log('-player1:');
    logPlayer(battle.player1);
    console.log('-player2:');
    logPlayer(battle.player2);
    console.log('-currentTurn:', battle.currentTurn.toString());
    console.log('-attacker:', Attacker[battle.attacker]);
    console.log('-turnHalves:', TurnHalves[battle.turnHalves]);
  };

  const logPlayer = (player: any) => {
    let str = '';

    console.log('--address:', player.playerAddr);
    console.log('--deckId:', player.deckId.toString());
    logHand(player.hand);
    for (let i = 0; i < 60; i++) {
      if (player.totalSupportCardIds[i].toNumber() == 0) {
        break;
      }
      str += `${player.totalSupportCardIds[i].toString()}, `;
    }
    console.log('--totalSupportCardIds:', str);
    console.log('--playedCardCount:', player.playedCardCount.toString());
  };

  const logHand = (hand: any) => {
    let str = '';

    console.log('--hand:');
    console.log('---health:', hand.health.toString());
    console.log('---battleCardId:', hand.battleCardId.toString());
    console.log('---tempBattleInfo:');
    console.log('----spd:', hand.tempBattleInfo.spd.toString());
    console.log('----inte:', hand.tempBattleInfo.inte.toString());
    console.log('----def:', hand.tempBattleInfo.def.toString());
    console.log('----atk:', hand.tempBattleInfo.atk.toString());
    console.log('----sAtk:', hand.tempBattleInfo.sAtk.toString());
    console.log('----sDef:', hand.tempBattleInfo.sDef.toString());
    for (let i = 0; i < hand.tempBattleInfo.inte; i++) {
      str += `${hand.supportCardIds[i]}, `;
    }
    console.log('---supportCardIds:', str);
    console.log('---tempSupportInfosCount:', hand.tempSupportInfosCount.toString());
    console.log('---tempSupportInfos:');
    for (let i = 0; i < hand.tempSupportInfosCount; i++) {
      logTempSupportInfo(hand.tempSupportInfos[i]);
    }
  };

  const logTempSupportInfo = (tempSupportInfo: any) => {
    console.log('----tempSupportInfo:');
    console.log('-----supportCardId:', tempSupportInfo.supportCardId);
    console.log('-----effectMany:');
    console.log('------power:', tempSupportInfo.effectMany.power.toString());
    console.log('------numTurns:', tempSupportInfo.effectMany.numTurns.toString());
    console.log('------effectTo:', EffectTo[tempSupportInfo.effectMany.effectTo]);
    console.log('------effectFor:', EffectFor[tempSupportInfo.effectMany.effectFor]);
    console.log('------reqCode:', tempSupportInfo.effectMany.reqCode.toString());
  };

  const logTurn = (turn: any) => {
    console.log('/********************************************|');
    console.log(`|                    Turn ${turn}                  |`);
    console.log('|___________________________________________*/');
  };

  const logTurnHalves = (turnHalves: any) => {
    console.log('/*********************|');
    console.log(`|        Half ${turnHalves}       |`);
    console.log('|____________________*/');
  };

  describe('#Battling', async () => {
    let battle: any;

    beforeEach(async () => {
      await battleContract.createBattle(alice.address, 1, bob.address, 2);
      battle = await battleContract.battles(1);
    });

    it('should fight', async () => {
      let result: any;

      console.log('--------------------- Create battle --------------------');
      logBattle(battle);
      // Turn 1
      logTurn(1);
      console.log('--------------------- Go for new turn --------------------');
      battle = await battleContract.goForNewTurn(battle);
      logBattle(battle);

      logTurnHalves(1);
      console.log('--------------------- Resolve attacker --------------------');
      battle = await battleContract.resolveAttacker(battle);
      logBattle(battle);
      console.log('--------------------- Fight --------------------');
      battle = await battleContract.fight(battle);
      logBattle(battle);
      console.log('--------------------- Check if battle ended --------------------');
      result = await battleContract.checkIfBattleEnded(battle);
      console.log('isEnded:', result[0]);
      console.log('winner address:', result[1]);
      console.log('--------------------- Go to second half --------------------');
      battle = await battleContract.resolveHalves(battle);
      logBattle(battle);

      logTurnHalves(2);
      console.log('--------------------- Resolve attacker --------------------');
      battle = await battleContract.resolveAttacker(battle);
      logBattle(battle);
      console.log('--------------------- Fight --------------------');
      battle = await battleContract.fight(battle);
      logBattle(battle);
      console.log('--------------------- Check if battle ended --------------------');
      result = await battleContract.checkIfBattleEnded(battle);
      console.log('isEnded:', result[0]);
      console.log('winner address:', result[1]);
      console.log('--------------------- Go for turn 2 --------------------');
      battle = await battleContract.resolveHalves(battle);
      logBattle(battle);
      // Turn 2
      logTurn(2);
      logTurnHalves(1);
      console.log('--------------------- Resolve attacker --------------------');
      battle = await battleContract.resolveAttacker(battle);
      logBattle(battle);
      console.log('--------------------- Fight --------------------');
      battle = await battleContract.fight(battle);
      logBattle(battle);
      console.log('--------------------- Check if battle ended --------------------');
      result = await battleContract.checkIfBattleEnded(battle);
      console.log('isEnded:', result[0]);
      console.log('winner address:', result[1]);
      console.log('--------------------- Go to second half --------------------');
      battle = await battleContract.resolveHalves(battle);
      logBattle(battle);

      logTurnHalves(2);
      console.log('--------------------- Resolve attacker --------------------');
      battle = await battleContract.resolveAttacker(battle);
      logBattle(battle);
      console.log('--------------------- Fight --------------------');
      battle = await battleContract.fight(battle);
      logBattle(battle);
      console.log('--------------------- Check if battle ended --------------------');
      result = await battleContract.checkIfBattleEnded(battle);
      console.log('isEnded:', result[0]);
      console.log('winner address:', result[1]);
      console.log('--------------------- Go for turn 3 --------------------');
      battle = await battleContract.resolveHalves(battle);
      logBattle(battle);
    });
  });
});
