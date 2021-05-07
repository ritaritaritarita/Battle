import {getProvider} from './helpers/contract';
import {PepemonBattle, PepemonCard, PepemonCardDeck} from '../typechain';
import {PepemonFactory} from "../typechain/PepemonFactory";


import DeckArtifact from '../artifacts/contracts/PepemonCardDeck.sol/PepemonCardDeck.json';
import CardArtifact from '../artifacts/contracts/PepemonCard.sol/PepemonCard.json';
import BattleArtifact from '../artifacts/contracts/PepemonBattle.sol/PepemonBattle.json';
import FactoryArtifact from '../contracts/abi/PepemonFactory.json';
import {deployContract, deployMockContract, MockContract} from 'ethereum-waffle';
import {BigNumber} from "ethers";

const [alice, bob] = getProvider().getWallets();

const roles = ['OFFENSE', 'DEFENSE', 'PENDING'];
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

describe('Battle', async () => {
    let battle: PepemonBattle;
    let deck: PepemonCardDeck | MockContract;
    let pepemonCardOracle: PepemonCard | MockContract;

    let battleCard: PepemonFactory | MockContract;
    let supportCard: PepemonFactory | MockContract;

    beforeEach(async () => {
        deck = await deployMockContract(alice, DeckArtifact.abi);
        pepemonCardOracle = await deployMockContract(alice, CardArtifact.abi);
        battleCard = await deployMockContract(alice, FactoryArtifact);
        supportCard = await deployMockContract(alice, FactoryArtifact);

        battle = (await deployContract(
            alice,
            BattleArtifact,
            [
                pepemonCardOracle.address,
                deck.address
            ]
        )) as PepemonBattle;


        await setupOracle();

        await setupDecks();
    });

    const setupOracle = async () => {
        await pepemonCardOracle.mock.getBattleCardById.withArgs(1).returns({
            battleCardId: 1,
            battleCardType: 0,
            name: "Pepesaur",
            hp: 450,
            spd: 10,
            inte: 5,
            def: 10,
            atk: 10,
            sAtk: 20,
            sDef: 20
        })

        await pepemonCardOracle.mock.getBattleCardById.withArgs(2).returns({
            battleCardId: 2,
            battleCardType: 0,
            name: "Pepemander",
            hp: 300,
            spd: 20,
            inte: 6,
            def: 8,
            atk: 12,
            sAtk: 24,
            sDef: 16
        })

        await pepemonCardOracle.mock.getSupportCardById.withArgs(1).returns({
            supportCardId: BigNumber.from(1),
            supportCardType: 0,
            name: "Fast Attack",
            effectOnes: [{
                power: 2,
                effectTo: 0,
                effectFor: 0,
                reqCode: 0
            }],
            effectMany: {
                power: 0,
                numTurns: 0,
                effectTo: 0,
                effectFor: 0,
                reqCode: 0
            },
            unstackable: true,
            unresettable: true
        })

        await pepemonCardOracle.mock.getSupportCardById.withArgs(2).returns({
            supportCardId: BigNumber.from(2),
            supportCardType: 0,
            name: "Mid Attack",
            effectOnes: [{
                power: 3,
                effectTo: 0,
                effectFor: 0,
                reqCode: 0
            }],
            effectMany: {
                power: 0,
                numTurns: 0,
                effectTo: 0,
                effectFor: 0,
                reqCode: 0
            },
            unstackable: true,
            unresettable: true
        })

        await pepemonCardOracle.mock.getSupportCardById.withArgs(3).returns({
            supportCardId: BigNumber.from(3),
            supportCardType: 0,
            name: "Haymaker Strike",
            effectOnes: [{
                power: 4,
                effectTo: 0,
                effectFor: 0,
                reqCode: 0
            }],
            effectMany: {
                power: 0,
                numTurns: 0,
                effectTo: 0,
                effectFor: 0,
                reqCode: 0
            },
            unstackable: true,
            unresettable: true
        })
    }

    const setupDecks = async () => {
        await deck.mock.playerToDecks.withArgs(alice.address).returns(1)
        await deck.mock.shuffleDeck.withArgs(1).returns([
            1, 1, 1, 2, 2, 2,
        ])
        await deck.mock.decks.withArgs(1).returns(
            BigNumber.from(1),
            BigNumber.from(999999999)
        )

        await deck.mock.playerToDecks.withArgs(bob.address).returns(2)
        await deck.mock.shuffleDeck.withArgs(2).returns([
            1, 1, 1, 2, 2, 2,
        ])
        await deck.mock.decks.withArgs(2).returns(
            BigNumber.from(2),
            BigNumber.from(999999999)
        )
    }

    describe('Battling', function () {
        it('should ', async function () {
            await battle.createBattle(alice.address, bob.address)

            await battle.fight(1)
        });
    });
});
