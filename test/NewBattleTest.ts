import { getProvider } from './helpers/contract';
import { PepemonBattle, PepemonCard, PepemonCardDeck } from '../typechain';
import { PepemonFactory } from "../typechain/PepemonFactory";


import DeckArtifact from '../artifacts/contracts/PepemonCardDeck.sol/PepemonCardDeck.json';
import CardArtifact from '../artifacts/contracts/PepemonCard.sol/PepemonCard.json';
import BattleArtifact from '../artifacts/contracts/PepemonBattle.sol/PepemonBattle.json';
import FactoryArtifact from '../contracts/abi/PepemonFactory.json';
import { deployContract, deployMockContract, MockContract } from 'ethereum-waffle';
import { BigNumber } from "ethers";

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
const EffectTo = ['ATTACK', 'STRONG_ATTACK', 'DEFENSE', 'STRONG_DEFENSE', 'SPEED', 'INTELLIGENCE'];
const EffectFor = ['ME', 'ENEMY'];
const Attacker = ['PLAYER_ONE', 'PLAYER_TWO'];
const TurnHalves = ['FIRST_HALF', 'SECOND_HALF'];

describe('::Battle', async () => {
	let battleContract: PepemonBattle;
	let pepemonDeckOracle: PepemonCardDeck | MockContract;
	let pepemonCardOracle: PepemonCard | MockContract;

	let battleCard: PepemonFactory | MockContract;
	let supportCard: PepemonFactory | MockContract;

	beforeEach(async () => {
		pepemonDeckOracle = await deployMockContract(alice, DeckArtifact.abi);
		pepemonCardOracle = await deployMockContract(alice, CardArtifact.abi);
		battleCard = await deployMockContract(alice, FactoryArtifact);
		supportCard = await deployMockContract(alice, FactoryArtifact);

		battleContract = (await deployContract(
			alice,
			BattleArtifact,
			[
				pepemonCardOracle.address,
				pepemonDeckOracle.address
			]
		)) as PepemonBattle;


		await setupCardOracle();

		await setupDeckOracle();
	});

	const setupCardOracle = async () => {
		await pepemonCardOracle.mock.getBattleCardById.withArgs(1).returns({
			battleCardId: BigNumber.from(1),
			battleCardType: 0,
			name: "Pepesaur",
			hp: BigNumber.from(450),
			spd: BigNumber.from(10),
			inte: BigNumber.from(5),
			def: BigNumber.from(10),
			atk: BigNumber.from(10),
			sAtk: BigNumber.from(20),
			sDef: BigNumber.from(20)
		});

		await pepemonCardOracle.mock.getBattleCardById.withArgs(2).returns({
			battleCardId: BigNumber.from(2),
			battleCardType: 0,
			name: "Pepemander",
			hp: BigNumber.from(300),
			spd: BigNumber.from(20),
			inte: BigNumber.from(6),
			def: BigNumber.from(8),
			atk: BigNumber.from(12),
			sAtk: BigNumber.from(24),
			sDef: BigNumber.from(16)
		});

		await pepemonCardOracle.mock.getSupportCardById.withArgs(1).returns({
			supportCardId: BigNumber.from(1),
			supportCardType: 0,
			name: "Fast Attack",
			effectOnes: [{
				power: BigNumber.from(2),
				effectTo: 0,
				effectFor: 0,
				reqCode: BigNumber.from(0)
			}],
			effectMany: {
				power: BigNumber.from(0),
				numTurns: BigNumber.from(0),
				effectTo: 0,
				effectFor: 0,
				reqCode: BigNumber.from(0)
			},
			unstackable: true,
			unresettable: true
		});

		await pepemonCardOracle.mock.getSupportCardById.withArgs(2).returns({
			supportCardId: BigNumber.from(2),
			supportCardType: 0,
			name: "Mid Attack",
			effectOnes: [{
				power: BigNumber.from(3),
				effectTo: 0,
				effectFor: 0,
				reqCode: BigNumber.from(0)
			}],
			effectMany: {
				power: BigNumber.from(0),
				numTurns: BigNumber.from(0),
				effectTo: 0,
				effectFor: 0,
				reqCode: BigNumber.from(0)
			},
			unstackable: true,
			unresettable: true
		});

		await pepemonCardOracle.mock.getSupportCardById.withArgs(3).returns({
			supportCardId: BigNumber.from(3),
			supportCardType: 0,
			name: "Haymaker Strike",
			effectOnes: [{
				power: BigNumber.from(4),
				effectTo: 0,
				effectFor: 0,
				reqCode: BigNumber.from(0)
			}],
			effectMany: {
				power: BigNumber.from(0),
				numTurns: BigNumber.from(0),
				effectTo: 0,
				effectFor: 0,
				reqCode: BigNumber.from(0)
			},
			unstackable: true,
			unresettable: true
		});
	};

	const setupDeckOracle = async () => {
		// Deck 1
		await pepemonDeckOracle.mock.shuffleDeck.withArgs(1).returns([
			1, 3, 1, 2, 3, 1, 3, 2, 1, 3, 1, 2, 3, 1, 3, 2, 1, 3, 1, 2,
			1, 3, 1, 2, 3, 1, 3, 2, 1, 3, 1, 2, 3, 1, 3, 2, 1, 3, 1, 2,
			1, 3, 1, 2, 3, 1, 3, 2, 1, 3
		]);
		await pepemonDeckOracle.mock.decks.withArgs(1).returns(
			BigNumber.from(1),
			BigNumber.from(50)
		);
		await pepemonDeckOracle.mock.getSupportCardCountInDeck.withArgs(1).returns(50);
		// Deck 2
		await pepemonDeckOracle.mock.shuffleDeck.withArgs(2).returns([
			3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1,
			3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1,
			3, 1, 2, 3, 1
		]);
		await pepemonDeckOracle.mock.decks.withArgs(2).returns(
			BigNumber.from(2),
			BigNumber.from(45)
		);
		await pepemonDeckOracle.mock.getSupportCardCountInDeck.withArgs(2).returns(45);
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

	describe('#Battling', async () => {
		let battle: any;

		beforeEach(async () => {
			await battleContract.createBattle(alice.address, 1, bob.address, 2);
			battle = await battleContract.battles(1);
		});
		it('should create battle', async () => {
			logBattle(battle);
		});
		it('should go for new turn', async () => {
			battle = await battleContract.goForNewTurn(battle);
			logBattle(battle);
		});
		it('should resolve attacker', async () => {
			battle = await battleContract.goForNewTurn(battle);
			battle = await battleContract.resolveAttacker(battle);
			logBattle(battle);
		});
		it('should calculate power boost', async () => {
			let result: any;

			battle = await battleContract.goForNewTurn(battle);
			// player2 is attacker and player1 is defender
			battle = await battleContract.resolveAttacker(battle);
			logBattle(battle);
			result = await battleContract.calPowerBoost(battle.player2.hand, battle.player1.hand);
			console.log('-attacker hand (player 2):');
			logHand(result[0]);
			console.log('------------------------------------------');
			console.log('-defender hand (player 1):');
			logHand(result[1]);
		});
		describe('##requirement code', async () => {
			beforeEach(async () => {
				battle = await battleContract.goForNewTurn(battle);
				// player2 is attacker and player1 is defender
				battle = await battleContract.resolveAttacker(battle);
				logBattle(battle);
				console.log('------------------------------------------');
			});
			it('should calculate requirement code 0', async () => {
				let result: any;
				console.log('-Code 0');
				result = await battleContract.checkReqCode(battle.player2.hand, battle.player1.hand, 0, true);
				console.log('isTriggered', result[0]);
				console.log('num:', result[1].toString());
			});
		});
	});
});
