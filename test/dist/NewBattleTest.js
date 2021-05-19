"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __generator = (this && this.__generator) || function (thisArg, body) {
    var _ = { label: 0, sent: function() { if (t[0] & 1) throw t[1]; return t[1]; }, trys: [], ops: [] }, f, y, t, g;
    return g = { next: verb(0), "throw": verb(1), "return": verb(2) }, typeof Symbol === "function" && (g[Symbol.iterator] = function() { return this; }), g;
    function verb(n) { return function (v) { return step([n, v]); }; }
    function step(op) {
        if (f) throw new TypeError("Generator is already executing.");
        while (_) try {
            if (f = 1, y && (t = op[0] & 2 ? y["return"] : op[0] ? y["throw"] || ((t = y["return"]) && t.call(y), 0) : y.next) && !(t = t.call(y, op[1])).done) return t;
            if (y = 0, t) op = [op[0] & 2, t.value];
            switch (op[0]) {
                case 0: case 1: t = op; break;
                case 4: _.label++; return { value: op[1], done: false };
                case 5: _.label++; y = op[1]; op = [0]; continue;
                case 7: op = _.ops.pop(); _.trys.pop(); continue;
                default:
                    if (!(t = _.trys, t = t.length > 0 && t[t.length - 1]) && (op[0] === 6 || op[0] === 2)) { _ = 0; continue; }
                    if (op[0] === 3 && (!t || (op[1] > t[0] && op[1] < t[3]))) { _.label = op[1]; break; }
                    if (op[0] === 6 && _.label < t[1]) { _.label = t[1]; t = op; break; }
                    if (t && _.label < t[2]) { _.label = t[2]; _.ops.push(op); break; }
                    if (t[2]) _.ops.pop();
                    _.trys.pop(); continue;
            }
            op = body.call(thisArg, _);
        } catch (e) { op = [6, e]; y = 0; } finally { f = t = 0; }
        if (op[0] & 5) throw op[1]; return { value: op[0] ? op[1] : void 0, done: true };
    }
};
exports.__esModule = true;
var contract_1 = require("./helpers/contract");
var PepemonCardDeck_json_1 = require("../artifacts/contracts/PepemonCardDeck.sol/PepemonCardDeck.json");
var PepemonCard_json_1 = require("../artifacts/contracts/PepemonCard.sol/PepemonCard.json");
var PepemonBattle_json_1 = require("../artifacts/contracts/PepemonBattle.sol/PepemonBattle.json");
var RandomNumberGenerator_json_1 = require("../artifacts/contracts/RandomNumberGenerator.sol/RandomNumberGenerator.json");
var ethereum_waffle_1 = require("ethereum-waffle");
var ethers_1 = require("ethers");
var _a = contract_1.getProvider().getWallets(), alice = _a[0], bob = _a[1];
var EffectTo = ['ATTACK', 'STRONG_ATTACK', 'DEFENSE', 'STRONG_DEFENSE', 'SPEED', 'INTELLIGENCE'];
var EffectFor = ['ME', 'ENEMY'];
var Attacker = ['PLAYER_ONE', 'PLAYER_TWO'];
var TurnHalves = ['FIRST_HALF', 'SECOND_HALF'];
describe('::Battle', function () { return __awaiter(void 0, void 0, void 0, function () {
    var battleContract, pepemonDeckOracle, pepemonCardOracle, randNrGen, setupCardOracle, setupDeckOracle, setupRandOracle, logBattle, logPlayer, logHand, logTempSupportInfo, logTurn, logTurnHalves;
    return __generator(this, function (_a) {
        beforeEach(function () { return __awaiter(void 0, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, ethereum_waffle_1.deployMockContract(alice, PepemonCardDeck_json_1["default"].abi)];
                    case 1:
                        pepemonDeckOracle = _a.sent();
                        return [4 /*yield*/, ethereum_waffle_1.deployMockContract(alice, PepemonCard_json_1["default"].abi)];
                    case 2:
                        pepemonCardOracle = _a.sent();
                        return [4 /*yield*/, ethereum_waffle_1.deployMockContract(alice, RandomNumberGenerator_json_1["default"].abi)];
                    case 3:
                        randNrGen = _a.sent();
                        return [4 /*yield*/, ethereum_waffle_1.deployContract(alice, PepemonBattle_json_1["default"], [
                                pepemonCardOracle.address,
                                pepemonDeckOracle.address,
                                randNrGen.address
                            ])];
                    case 4:
                        battleContract = (_a.sent());
                        return [4 /*yield*/, setupCardOracle()];
                    case 5:
                        _a.sent();
                        return [4 /*yield*/, setupDeckOracle()];
                    case 6:
                        _a.sent();
                        return [4 /*yield*/, setupRandOracle()];
                    case 7:
                        _a.sent();
                        return [2 /*return*/];
                }
            });
        }); });
        setupCardOracle = function () { return __awaiter(void 0, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, pepemonCardOracle.mock.getBattleCardById.withArgs(1).returns({
                            battleCardId: ethers_1.BigNumber.from(1),
                            battleCardType: 0,
                            name: "Pepesaur",
                            hp: ethers_1.BigNumber.from(50),
                            // hp: BigNumber.from(450),
                            spd: ethers_1.BigNumber.from(10),
                            inte: ethers_1.BigNumber.from(5),
                            def: ethers_1.BigNumber.from(10),
                            atk: ethers_1.BigNumber.from(10),
                            sAtk: ethers_1.BigNumber.from(20),
                            sDef: ethers_1.BigNumber.from(20)
                        })];
                    case 1:
                        _a.sent();
                        return [4 /*yield*/, pepemonCardOracle.mock.getBattleCardById.withArgs(2).returns({
                                battleCardId: ethers_1.BigNumber.from(2),
                                battleCardType: 0,
                                name: "Pepemander",
                                hp: ethers_1.BigNumber.from(30),
                                // hp: BigNumber.from(300),
                                spd: ethers_1.BigNumber.from(20),
                                inte: ethers_1.BigNumber.from(6),
                                def: ethers_1.BigNumber.from(8),
                                atk: ethers_1.BigNumber.from(12),
                                sAtk: ethers_1.BigNumber.from(24),
                                sDef: ethers_1.BigNumber.from(16)
                            })];
                    case 2:
                        _a.sent();
                        return [4 /*yield*/, pepemonCardOracle.mock.getSupportCardById.withArgs(1).returns({
                                supportCardId: ethers_1.BigNumber.from(1),
                                supportCardType: 0,
                                name: "Fast Attack",
                                effectOnes: [{
                                        power: ethers_1.BigNumber.from(2),
                                        effectTo: 0,
                                        effectFor: 0,
                                        reqCode: ethers_1.BigNumber.from(0)
                                    }],
                                effectMany: {
                                    power: ethers_1.BigNumber.from(0),
                                    numTurns: ethers_1.BigNumber.from(0),
                                    effectTo: 0,
                                    effectFor: 0,
                                    reqCode: ethers_1.BigNumber.from(0)
                                },
                                unstackable: true,
                                unresettable: true
                            })];
                    case 3:
                        _a.sent();
                        return [4 /*yield*/, pepemonCardOracle.mock.getSupportCardById.withArgs(2).returns({
                                supportCardId: ethers_1.BigNumber.from(2),
                                supportCardType: 0,
                                name: "Mid Attack",
                                effectOnes: [{
                                        power: ethers_1.BigNumber.from(3),
                                        effectTo: 0,
                                        effectFor: 0,
                                        reqCode: ethers_1.BigNumber.from(0)
                                    }],
                                effectMany: {
                                    power: ethers_1.BigNumber.from(0),
                                    numTurns: ethers_1.BigNumber.from(0),
                                    effectTo: 0,
                                    effectFor: 0,
                                    reqCode: ethers_1.BigNumber.from(0)
                                },
                                unstackable: true,
                                unresettable: true
                            })];
                    case 4:
                        _a.sent();
                        return [4 /*yield*/, pepemonCardOracle.mock.getSupportCardById.withArgs(3).returns({
                                supportCardId: ethers_1.BigNumber.from(3),
                                supportCardType: 0,
                                name: "Haymaker Strike",
                                effectOnes: [{
                                        power: ethers_1.BigNumber.from(4),
                                        effectTo: 0,
                                        effectFor: 0,
                                        reqCode: ethers_1.BigNumber.from(0)
                                    }],
                                effectMany: {
                                    power: ethers_1.BigNumber.from(0),
                                    numTurns: ethers_1.BigNumber.from(0),
                                    effectTo: 0,
                                    effectFor: 0,
                                    reqCode: ethers_1.BigNumber.from(0)
                                },
                                unstackable: true,
                                unresettable: true
                            })];
                    case 5:
                        _a.sent();
                        return [2 /*return*/];
                }
            });
        }); };
        setupDeckOracle = function () { return __awaiter(void 0, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: 
                    // Deck 1
                    return [4 /*yield*/, pepemonDeckOracle.mock.shuffleDeck.withArgs(1).returns([
                            1, 3, 1, 2, 3, 1, 3, 2, 1, 3, 1, 2, 3, 1, 3, 2, 1, 3, 1, 2,
                            1, 3, 1, 2, 3, 1, 3, 2, 1, 3, 1, 2, 3, 1, 3, 2, 1, 3, 1, 2,
                            1, 3, 1, 2, 3, 1, 3, 2, 1, 3
                        ])];
                    case 1:
                        // Deck 1
                        _a.sent();
                        return [4 /*yield*/, pepemonDeckOracle.mock.decks.withArgs(1).returns(ethers_1.BigNumber.from(1), ethers_1.BigNumber.from(50))];
                    case 2:
                        _a.sent();
                        return [4 /*yield*/, pepemonDeckOracle.mock.getSupportCardCountInDeck.withArgs(1).returns(50)];
                    case 3:
                        _a.sent();
                        // Deck 2
                        return [4 /*yield*/, pepemonDeckOracle.mock.shuffleDeck.withArgs(2).returns([
                                3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1,
                                3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1, 3, 1, 2, 3, 1,
                                3, 1, 2, 3, 1
                            ])];
                    case 4:
                        // Deck 2
                        _a.sent();
                        return [4 /*yield*/, pepemonDeckOracle.mock.decks.withArgs(2).returns(ethers_1.BigNumber.from(2), ethers_1.BigNumber.from(45))];
                    case 5:
                        _a.sent();
                        return [4 /*yield*/, pepemonDeckOracle.mock.getSupportCardCountInDeck.withArgs(2).returns(45)];
                    case 6:
                        _a.sent();
                        return [2 /*return*/];
                }
            });
        }); };
        setupRandOracle = function () { return __awaiter(void 0, void 0, void 0, function () {
            return __generator(this, function (_a) {
                switch (_a.label) {
                    case 0: return [4 /*yield*/, randNrGen.mock.getRandomNumber.returns(10)];
                    case 1:
                        _a.sent();
                        return [2 /*return*/];
                }
            });
        }); };
        logBattle = function (battle) {
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
        logPlayer = function (player) {
            var str = '';
            console.log('--address:', player.playerAddr);
            console.log('--deckId:', player.deckId.toString());
            logHand(player.hand);
            for (var i = 0; i < 60; i++) {
                if (player.totalSupportCardIds[i].toNumber() == 0) {
                    break;
                }
                str += player.totalSupportCardIds[i].toString() + ", ";
            }
            console.log('--totalSupportCardIds:', str);
            console.log('--playedCardCount:', player.playedCardCount.toString());
        };
        logHand = function (hand) {
            var str = '';
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
            for (var i = 0; i < hand.tempBattleInfo.inte; i++) {
                str += hand.supportCardIds[i] + ", ";
            }
            console.log('---supportCardIds:', str);
            console.log('---tempSupportInfosCount:', hand.tempSupportInfosCount.toString());
            console.log('---tempSupportInfos:');
            for (var i = 0; i < hand.tempSupportInfosCount; i++) {
                logTempSupportInfo(hand.tempSupportInfos[i]);
            }
        };
        logTempSupportInfo = function (tempSupportInfo) {
            console.log('----tempSupportInfo:');
            console.log('-----supportCardId:', tempSupportInfo.supportCardId);
            console.log('-----effectMany:');
            console.log('------power:', tempSupportInfo.effectMany.power.toString());
            console.log('------numTurns:', tempSupportInfo.effectMany.numTurns.toString());
            console.log('------effectTo:', EffectTo[tempSupportInfo.effectMany.effectTo]);
            console.log('------effectFor:', EffectFor[tempSupportInfo.effectMany.effectFor]);
            console.log('------reqCode:', tempSupportInfo.effectMany.reqCode.toString());
        };
        logTurn = function (turn) {
            console.log('/********************************************|');
            console.log("|                    Turn " + turn + "                  |");
            console.log('|___________________________________________*/');
        };
        logTurnHalves = function (turnHalves) {
            console.log('/*********************|');
            console.log("|        Half " + turnHalves + "       |");
            console.log('|____________________*/');
        };
        describe('#Battling', function () { return __awaiter(void 0, void 0, void 0, function () {
            var battle;
            return __generator(this, function (_a) {
                beforeEach(function () { return __awaiter(void 0, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0: return [4 /*yield*/, battleContract.createBattle(alice.address, 1, bob.address, 2)];
                            case 1:
                                _a.sent();
                                return [4 /*yield*/, battleContract.battles(1)];
                            case 2:
                                battle = _a.sent();
                                return [2 /*return*/];
                        }
                    });
                }); });
                it('should fight', function () { return __awaiter(void 0, void 0, void 0, function () {
                    var result;
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                console.log('--------------------- Create battle --------------------');
                                logBattle(battle);
                                // Turn 1
                                logTurn(1);
                                console.log('--------------------- Go for new turn --------------------');
                                return [4 /*yield*/, battleContract.goForNewTurn(battle)];
                            case 1:
                                battle = _a.sent();
                                logBattle(battle);
                                logTurnHalves(1);
                                console.log('--------------------- Resolve attacker --------------------');
                                return [4 /*yield*/, battleContract.resolveAttacker(battle)];
                            case 2:
                                battle = _a.sent();
                                logBattle(battle);
                                console.log('--------------------- Fight --------------------');
                                return [4 /*yield*/, battleContract.fight(battle)];
                            case 3:
                                battle = _a.sent();
                                logBattle(battle);
                                console.log('--------------------- Check if battle ended --------------------');
                                return [4 /*yield*/, battleContract.checkIfBattleEnded(battle)];
                            case 4:
                                result = _a.sent();
                                console.log('isEnded:', result[0]);
                                console.log('winner address:', result[1]);
                                console.log('--------------------- Go to second half --------------------');
                                return [4 /*yield*/, battleContract.resolveHalves(battle)];
                            case 5:
                                battle = _a.sent();
                                logBattle(battle);
                                logTurnHalves(2);
                                console.log('--------------------- Resolve attacker --------------------');
                                return [4 /*yield*/, battleContract.resolveAttacker(battle)];
                            case 6:
                                battle = _a.sent();
                                logBattle(battle);
                                console.log('--------------------- Fight --------------------');
                                return [4 /*yield*/, battleContract.fight(battle)];
                            case 7:
                                battle = _a.sent();
                                logBattle(battle);
                                console.log('--------------------- Check if battle ended --------------------');
                                return [4 /*yield*/, battleContract.checkIfBattleEnded(battle)];
                            case 8:
                                result = _a.sent();
                                console.log('isEnded:', result[0]);
                                console.log('winner address:', result[1]);
                                console.log('--------------------- Go for turn 2 --------------------');
                                return [4 /*yield*/, battleContract.resolveHalves(battle)];
                            case 9:
                                battle = _a.sent();
                                logBattle(battle);
                                // Turn 2
                                logTurn(2);
                                logTurnHalves(1);
                                console.log('--------------------- Resolve attacker --------------------');
                                return [4 /*yield*/, battleContract.resolveAttacker(battle)];
                            case 10:
                                battle = _a.sent();
                                logBattle(battle);
                                console.log('--------------------- Fight --------------------');
                                return [4 /*yield*/, battleContract.fight(battle)];
                            case 11:
                                battle = _a.sent();
                                logBattle(battle);
                                console.log('--------------------- Check if battle ended --------------------');
                                return [4 /*yield*/, battleContract.checkIfBattleEnded(battle)];
                            case 12:
                                result = _a.sent();
                                console.log('isEnded:', result[0]);
                                console.log('winner address:', result[1]);
                                console.log('--------------------- Go to second half --------------------');
                                return [4 /*yield*/, battleContract.resolveHalves(battle)];
                            case 13:
                                battle = _a.sent();
                                logBattle(battle);
                                logTurnHalves(2);
                                console.log('--------------------- Resolve attacker --------------------');
                                return [4 /*yield*/, battleContract.resolveAttacker(battle)];
                            case 14:
                                battle = _a.sent();
                                logBattle(battle);
                                console.log('--------------------- Fight --------------------');
                                return [4 /*yield*/, battleContract.fight(battle)];
                            case 15:
                                battle = _a.sent();
                                logBattle(battle);
                                console.log('--------------------- Check if battle ended --------------------');
                                return [4 /*yield*/, battleContract.checkIfBattleEnded(battle)];
                            case 16:
                                result = _a.sent();
                                console.log('isEnded:', result[0]);
                                console.log('winner address:', result[1]);
                                console.log('--------------------- Go for turn 3 --------------------');
                                return [4 /*yield*/, battleContract.resolveHalves(battle)];
                            case 17:
                                battle = _a.sent();
                                logBattle(battle);
                                return [2 /*return*/];
                        }
                    });
                }); });
                it('should go for battle', function () { return __awaiter(void 0, void 0, void 0, function () {
                    return __generator(this, function (_a) {
                        switch (_a.label) {
                            case 0:
                                console.log('--------------------- Create battle --------------------');
                                logBattle(battle);
                                return [4 /*yield*/, battleContract.goForBattle(battle)];
                            case 1:
                                battle = _a.sent();
                                logBattle(battle);
                                return [2 /*return*/];
                        }
                    });
                }); });
                return [2 /*return*/];
            });
        }); });
        return [2 /*return*/];
    });
}); });
