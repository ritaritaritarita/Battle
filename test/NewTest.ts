import { getProvider } from './helpers/contract';
import { PepemonBattle, PepemonCardOracle, PepemonCardDeck, RandomNumberGenerator } from '../typechain';
import { deployContract, deployMockContract, MockContract } from 'ethereum-waffle';
import DeckArtifact from '../artifacts/contracts/PepemonCardDeck.sol/PepemonCardDeck.json';
import CardArtifact from '../artifacts/contracts/PepemonCardOracle.sol/PepemonCardOracle.json';
import RNGArtifact from '../artifacts/contracts/RandomNumberGenerator.sol/RandomNumberGenerator.json';
import BattleArtifact from '../artifacts/contracts/PepemonBattle.sol/PepemonBattle.json';

import * as Pepesaur from './battle_setups/battle_cards/01.json';
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
    pepemonCardOracle = await deployMockContract(alice, CardArtifact.abi);
    rng = await deployMockContract(alice, RNGArtifact.abi);

    battleContract = (await deployContract(alice, BattleArtifact, [
      pepemonCardOracle.address,
      pepemonDeckOracle.address,
      rng.address,
    ])) as PepemonBattle;

    await setupCardOracle();
    await setupDeck();
    await setupRng();
  });

  async function setupCardOracle() {
    await pepemonCardOracle.mock.getBattleCardById.withArgs(1).returns({
      battleCardId: Pepesaur.battle_card_id,
      battleCardType: Pepesaur.stats.battle_card_type,
      name: Pepesaur.name,
      hp: BigNumber.from(Pepesaur.stats.hp),
      spd: BigNumber.from(Pepesaur.stats.spd),
      inte: BigNumber.from(Pepesaur.stats.inte),
      def: BigNumber.from(Pepesaur.stats.def),
      atk: BigNumber.from(Pepesaur.stats.atk),
      sAtk: BigNumber.from(Pepesaur.stats.sAtk),
      sDef: BigNumber.from(Pepesaur.stats.sDef),
    });
  }

  async function setupDeck() {
    // Deck 1
    await pepemonDeckOracle.mock.shuffleDeck
      .withArgs(1)
      .returns([
        1,
        3,
        1,
        2,
        3,
        1,
        3,
        2,
        1,
        3,
        1,
        2,
        3,
        1,
        3,
        2,
        1,
        3,
        1,
        2,
        1,
        3,
        1,
        2,
        3,
        1,
        3,
        2,
        1,
        3,
        1,
        2,
        3,
        1,
        3,
        2,
        1,
        3,
        1,
        2,
        1,
        3,
        1,
        2,
        3,
        1,
        3,
        2,
        1,
        3,
      ]);

    await pepemonDeckOracle.mock.decks.withArgs(1).returns(BigNumber.from(1), BigNumber.from(50));
    await pepemonDeckOracle.mock.getSupportCardCountInDeck.withArgs(1).returns(50);

    // Deck 2
    await pepemonDeckOracle.mock.shuffleDeck
      .withArgs(2)
      .returns([
        3,
        1,
        2,
        3,
        1,
        3,
        1,
        2,
        3,
        1,
        3,
        1,
        2,
        3,
        1,
        3,
        1,
        2,
        3,
        1,
        3,
        1,
        2,
        3,
        1,
        3,
        1,
        2,
        3,
        1,
        3,
        1,
        2,
        3,
        1,
        3,
        1,
        2,
        3,
        1,
        3,
        1,
        2,
        3,
        1,
      ]);
    await pepemonDeckOracle.mock.decks.withArgs(2).returns(BigNumber.from(2), BigNumber.from(45));
    await pepemonDeckOracle.mock.getSupportCardCountInDeck.withArgs(2).returns(45);
  }

  async function setupRng() {}
});
