// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PepemonCardDeck.sol";
import "./PepemonCard.sol";
import "./RandomNumberGenerator.sol";

contract PepemonBattle is Ownable {
    using SafeMath for uint256;

    event BattleCreated(uint256 battleId, address player1Addr, address player2Addr);
    event BattleEnded(uint256 battleId, address winnerAddr);

    enum Attacker {PLAYER_ONE, PLAYER_TWO}
    enum TurnHalves {FIRST_HALF, SECOND_HALF}

    struct Battle {
        uint256 battleId;
        Player player1;
        Player player2;
        uint256 currentTurn;
        Attacker attacker;
        TurnHalves turnHalves;
    }

    struct Player {
        address playerAddr;
        uint256 deckId;
        Hand hand;
        uint256[60] totalSupportCardIds;
        uint256 playedCardCount;
    }

    struct Hand {
        int256 health;
        uint256 battleCardId;
        TempBattleInfo tempBattleInfo;
        uint256[7] supportCardIds;
        uint256 tempSupportInfosCount;
        TempSupportInfo[5] tempSupportInfos;
    }

    struct TempBattleInfo {
        uint256 spd;
        uint256 inte;
        uint256 def;
        uint256 atk;
        uint256 sAtk;
        uint256 sDef;
    }

    struct TempSupportInfo {
        uint256 supportCardId;
        PepemonCard.EffectMany effectMany;
    }

    mapping(uint256 => Battle) public battles;

    uint256 private _nextBattleId;
    uint8 private _refreshTurn = 5;
    uint256 private _randNonce = 0;

    // todo oracle
    PepemonCard private _cardContract;
    PepemonCardDeck private _deckContract;
    RandomNumberGenerator private _randNrGenContract;

    // todo card address needs to be changed to card oracle address
    constructor(
        address cardOracleAddress,
        address deckOracleAddress,
        address randOracleAddress
    ) {
        _cardContract = PepemonCard(cardOracleAddress);
        _deckContract = PepemonCardDeck(deckOracleAddress);
        _randNrGenContract = RandomNumberGenerator(randOracleAddress);
        _nextBattleId = 1;
    }

    /**
     * @dev Create battle
     * @param p1Addr address player1
     * @param p1DeckId uint256
     * @param p2Addr address player2
     * @param p2DeckId uint256
     */
    function createBattle(
        address p1Addr,
        uint256 p1DeckId,
        address p2Addr,
        uint256 p2DeckId
    ) public onlyOwner {
        require(p1Addr != p2Addr, "PepemonBattle: Cannot battle yourself");

        (uint256 p1BattleCardId, ) = _deckContract.decks(p1DeckId);
        (uint256 p2BattleCardId, ) = _deckContract.decks(p2DeckId);
        PepemonCard.BattleCardStats memory p1BattleCard = _cardContract.getBattleCardById(p1BattleCardId);
        PepemonCard.BattleCardStats memory p2BattleCard = _cardContract.getBattleCardById(p2BattleCardId);
        // Initiate battle ID
        battles[_nextBattleId].battleId = _nextBattleId;
        // Initiate player1
        battles[_nextBattleId].player1.hand.health = int256(p1BattleCard.hp);
        battles[_nextBattleId].player1.hand.battleCardId = p1BattleCardId;
        battles[_nextBattleId].player1.playerAddr = p1Addr;
        battles[_nextBattleId].player1.deckId = p1DeckId;
        // Initiate player2
        battles[_nextBattleId].player2.hand.health = int256(p2BattleCard.hp);
        battles[_nextBattleId].player2.hand.battleCardId = p2BattleCardId;
        battles[_nextBattleId].player2.playerAddr = p2Addr;
        battles[_nextBattleId].player2.deckId = p2DeckId;
        // Emit event
        emit BattleCreated(_nextBattleId, p1Addr, p2Addr);
        _nextBattleId = _nextBattleId.add(1);

        // Battle memory battle = goForBattle(battles[_nextBattleId]);
        // return battle;
    }

    function goForBattle(Battle memory battle) public view returns (Battle memory) {
        battle = goForNewTurn(battle);
        // Battle goes!
        while (true) {
            // Resolve attacker in the current turn
            battle = resolveAttacker(battle);
            // Fight
            battle = fight(battle);

            // Check if battle ended
            (bool isEnded, address winnerAddr) = checkIfBattleEnded(battle);
            if (isEnded) {
                // emit BattleEnded(battle.battleId, winnerAddr);
                break;
            }

            // Resolve turn halves
            battle = resolveHalves(battle);
        }
        return battle;
    }

    function resolveHalves(Battle memory battle) public view returns (Battle memory) {
        // If the current half is first, go over second half
        // or go over next turn
        if (battle.turnHalves == TurnHalves.FIRST_HALF) {
            battle.turnHalves = TurnHalves.SECOND_HALF;
        } else {
            battle = goForNewTurn(battle);
        }

        return battle;
    }

    function goForNewTurn(Battle memory battle) public view returns (Battle memory) {
        Player memory player1 = battle.player1;
        Player memory player2 = battle.player2;

        // Initiate tempBattleInfo of both players
        PepemonCard.BattleCardStats memory p1BattleCard = _cardContract.getBattleCardById(player1.hand.battleCardId);
        PepemonCard.BattleCardStats memory p2BattleCard = _cardContract.getBattleCardById(player2.hand.battleCardId);

        player1.hand.tempBattleInfo.spd = p1BattleCard.spd;
        player1.hand.tempBattleInfo.inte = p1BattleCard.inte;
        player1.hand.tempBattleInfo.def = p1BattleCard.def;
        player1.hand.tempBattleInfo.atk = p1BattleCard.atk;
        player1.hand.tempBattleInfo.sAtk = p1BattleCard.sAtk;
        player1.hand.tempBattleInfo.sDef = p1BattleCard.sDef;

        player2.hand.tempBattleInfo.spd = p2BattleCard.spd;
        player2.hand.tempBattleInfo.inte = p2BattleCard.inte;
        player2.hand.tempBattleInfo.def = p2BattleCard.def;
        player2.hand.tempBattleInfo.atk = p2BattleCard.atk;
        player2.hand.tempBattleInfo.sAtk = p2BattleCard.sAtk;
        player2.hand.tempBattleInfo.sDef = p2BattleCard.sDef;

        bool isRefreshTurn = (battle.currentTurn % _refreshTurn == 0 ? true : false);
        if (!isRefreshTurn) {
            // Get temp support info of previous turn's hands and calculate their effect for the new turn
            player1.hand = calTempPowerBoost(player1.hand);
            player2.hand = calTempPowerBoost(player2.hand);
        }
        // Draw support cards by temp battle info inte and speed
        if (isRefreshTurn) {
            // Shuffle player1 support cards
            uint256 p1SupportCardIdsLength = _deckContract.getSupportCardCountInDeck(player1.deckId);
            for (uint256 i = 0; i < p1SupportCardIdsLength; i++) {
                player1.totalSupportCardIds[i] = _deckContract.shuffleDeck(player1.deckId)[i];
            }
            player1.playedCardCount = 0;
            // Shuffle player2 support cards
            uint256 p2SupportCardIdsLength = _deckContract.getSupportCardCountInDeck(player2.deckId);
            for (uint256 i = 0; i < p2SupportCardIdsLength; i++) {
                player2.totalSupportCardIds[i] = _deckContract.shuffleDeck(player2.deckId)[i];
            }
            player2.playedCardCount = 0;
        }
        // Draw player1 support cards for the new turn
        for (uint256 i = 0; i < player1.hand.tempBattleInfo.inte; i++) {
            player1.hand.supportCardIds[i] = player1.totalSupportCardIds[i + player1.playedCardCount];
        }
        player1.playedCardCount += player1.hand.tempBattleInfo.inte;
        // Draw player2 support cards for the new turn
        for (uint256 i = 0; i < player2.hand.tempBattleInfo.inte; i++) {
            player2.hand.supportCardIds[i] = player2.totalSupportCardIds[i + player2.playedCardCount];
        }
        player2.playedCardCount += player2.hand.tempBattleInfo.inte;

        battle.player1 = player1;
        battle.player2 = player2;
        // Increment current turn number of battle
        battle.currentTurn++;
        // Go for first half in turn
        battle.turnHalves = TurnHalves.FIRST_HALF;

        return battle;
    }

    function calTempPowerBoost(Hand memory hand) public pure returns (Hand memory) {
        for (uint256 i = 0; i < hand.tempSupportInfosCount; i++) {
            TempSupportInfo memory tempSupportInfo = hand.tempSupportInfos[i];
            PepemonCard.EffectMany memory effect = tempSupportInfo.effectMany;
            if (effect.numTurns >= 1) {
                if (effect.effectFor == PepemonCard.EffectFor.ME) {
                    // Currently effectTo of EffectMany can be ATTACK, DEFENSE, SPEED and INTELLIGENCE
                    int256 temp;
                    if (effect.effectTo == PepemonCard.EffectTo.ATTACK) {
                        temp = int256(hand.tempBattleInfo.atk) + effect.power;
                        hand.tempBattleInfo.atk = uint256(temp);
                    } else if (effect.effectTo == PepemonCard.EffectTo.DEFENSE) {
                        temp = int256(hand.tempBattleInfo.def) + effect.power;
                        hand.tempBattleInfo.def = uint256(temp);
                    } else if (effect.effectTo == PepemonCard.EffectTo.SPEED) {
                        temp = int256(hand.tempBattleInfo.spd) + effect.power;
                        hand.tempBattleInfo.spd = uint256(temp);
                    } else if (effect.effectTo == PepemonCard.EffectTo.INTELLIGENCE) {
                        temp = int256(hand.tempBattleInfo.inte) + effect.power;
                        hand.tempBattleInfo.inte = uint256(temp);
                    }
                } else {
                    // Currently effectFor of EffectMany can only be ME so ignored ENEMY
                }
                // Decrease effect numTurns by 1
                effect.numTurns = effect.numTurns.sub(1);
                // Delete this one from tempSupportInfo if the card is no longer available
                if (effect.numTurns == 0) {
                    if (i < hand.tempSupportInfosCount - 1) {
                        hand.tempSupportInfos[i] = hand.tempSupportInfos[hand.tempSupportInfosCount - 1];
                    }
                    delete hand.tempSupportInfos[hand.tempSupportInfosCount - 1];
                    hand.tempSupportInfosCount--;
                    continue;
                }
            }
        }

        return hand;
    }

    function resolveAttacker(Battle memory battle) public view returns (Battle memory) {
        TempBattleInfo memory p1TempBattleInfo = battle.player1.hand.tempBattleInfo;
        TempBattleInfo memory p2TempBattleInfo = battle.player2.hand.tempBattleInfo;

        if (battle.turnHalves == TurnHalves.FIRST_HALF) {
            if (p1TempBattleInfo.spd > p2TempBattleInfo.spd) {
                battle.attacker = Attacker.PLAYER_ONE;
            } else if (p1TempBattleInfo.spd < p2TempBattleInfo.spd) {
                battle.attacker = Attacker.PLAYER_TWO;
            } else {
                if (p1TempBattleInfo.inte > p2TempBattleInfo.inte) {
                    battle.attacker = Attacker.PLAYER_ONE;
                } else if (p1TempBattleInfo.inte < p2TempBattleInfo.inte) {
                    battle.attacker = Attacker.PLAYER_TWO;
                } else {
                    uint256 rand = _randMod(2);
                    battle.attacker = (rand == 0 ? Attacker.PLAYER_ONE : Attacker.PLAYER_TWO);
                }
            }
        } else {
            battle.attacker = (battle.attacker == Attacker.PLAYER_ONE ? Attacker.PLAYER_TWO : Attacker.PLAYER_ONE);
        }

        return battle;
    }

    /**
     * @dev Generate random number in a range
     * @param modulus uint256
     */
    function _randMod(uint256 modulus) private view returns (uint256) {
        // todo needs to connect to chain link
        uint256 randomNumber = _randNrGenContract.getRandomNumber();
        return randomNumber % modulus;
        // _randNonce++;
        // return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _randNonce))) % modulus;
    }

    function checkIfBattleEnded(Battle memory battle) public pure returns (bool, address) {
        if (battle.player1.hand.health <= 0) {
            return (true, battle.player1.playerAddr);
        } else if (battle.player2.hand.health <= 0) {
            return (true, battle.player2.playerAddr);
        } else {
            return (false, address(0));
        }
    }

    function fight(Battle memory battle) public view returns (Battle memory) {
        Hand memory atkHand;
        Hand memory defHand;

        if (battle.attacker == Attacker.PLAYER_ONE) {
            atkHand = battle.player1.hand;
            defHand = battle.player2.hand;
        } else {
            atkHand = battle.player2.hand;
            defHand = battle.player1.hand;
        }
        (atkHand, defHand) = calPowerBoost(atkHand, defHand);
        // Fight
        if (atkHand.tempBattleInfo.atk > defHand.tempBattleInfo.def) {
            defHand.health -= int256(atkHand.tempBattleInfo.atk - defHand.tempBattleInfo.def);
        } else {
            defHand.health -= 1;
        }

        if (battle.attacker == Attacker.PLAYER_ONE) {
            battle.player1.hand = atkHand;
            battle.player2.hand = defHand;
        } else {
            battle.player1.hand = defHand;
            battle.player2.hand = atkHand;
        }

        return battle;
    }

    function calPowerBoost(Hand memory atkHand, Hand memory defHand) public view returns (Hand memory, Hand memory) {
        // If this card is included in player's hand, adds an additional power equal to the total of
        // all normal offense/defense cards
        bool isPower0CardIncluded = false;
        // Total sum of normal support cards
        int256 totalNormalPower = 0;
        // Cal attacker hand
        for (uint256 i = 0; i < atkHand.tempBattleInfo.inte; i++) {
            uint256 id = atkHand.supportCardIds[i];
            PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(id);
            if (card.supportCardType == PepemonCard.SupportCardType.OFFENSE) {
                // Card type is OFFENSE.
                // Calc effects of EffectOne array
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCard.EffectOne memory effectOne = card.effectOnes[j];
                    (bool isTriggered, uint256 num) = checkReqCode(atkHand, defHand, effectOne.reqCode, true);
                    if (isTriggered) {
                        if (num > 0) {
                            int256 temp;
                            temp = int256(atkHand.tempBattleInfo.atk) + effectOne.power * int256(num);
                            atkHand.tempBattleInfo.atk = uint256(temp);
                            totalNormalPower += effectOne.power * int256(num);
                        } else {
                            int256 temp;
                            temp = int256(atkHand.tempBattleInfo.atk) + effectOne.power;
                            atkHand.tempBattleInfo.atk = uint256(temp);
                            totalNormalPower += effectOne.power;
                        }
                    }
                }
            } else if (card.supportCardType == PepemonCard.SupportCardType.STRONG_OFFENSE) {
                // Card type is STRONG OFFENSE.
                if (card.unstackable) {
                    bool isNew = true;
                    // Check if card is new to previous cards
                    for (uint256 j = 0; j < i; j++) {
                        if (id == atkHand.supportCardIds[j]) {
                            isNew = false;
                            break;
                        }
                    }
                    if (!isNew) {
                        continue;
                    }
                    // Check if card is new to temp support info cards
                    for (uint256 j = 0; j < atkHand.tempSupportInfosCount; j++) {
                        if (id == atkHand.tempSupportInfos[j].supportCardId) {
                            isNew = false;
                            break;
                        }
                    }
                    if (!isNew) {
                        continue;
                    }
                }
                // Calc effects of EffectOne array
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCard.EffectOne memory effectOne = card.effectOnes[j];
                    (bool isTriggered, uint256 num) = checkReqCode(atkHand, defHand, effectOne.reqCode, true);
                    if (isTriggered) {
                        if (num > 0) {
                            int256 temp;
                            temp = int256(atkHand.tempBattleInfo.atk) + effectOne.power * int256(num);
                            atkHand.tempBattleInfo.atk = uint256(temp);
                        } else {
                            if (effectOne.effectTo == PepemonCard.EffectTo.STRONG_ATTACK) {
                                atkHand.tempBattleInfo.atk = atkHand.tempBattleInfo.sAtk;
                                continue;
                            } else if (effectOne.power == 0) {
                                // Equal to the total of all offense cards in the current turn
                                isPower0CardIncluded = true;
                                continue;
                            }
                            int256 temp;
                            temp = int256(atkHand.tempBattleInfo.atk) + effectOne.power;
                            atkHand.tempBattleInfo.atk = uint256(temp);
                        }
                    }
                }
                // If card has non-empty effectMany.
                if (card.effectMany.power != 0) {
                    // Add card info to temp support info ids if number of temp support infos did not reach maximu (5) yet.
                    if (atkHand.tempSupportInfosCount < 5) {
                        atkHand.tempSupportInfos[atkHand.tempSupportInfosCount++] = TempSupportInfo({
                            supportCardId: id,
                            effectMany: card.effectMany
                        });
                    }
                }
            } else {
                // Other card type is ignored.
                continue;
            }
        }
        if (isPower0CardIncluded) {
            int256 temp;
            temp = int256(atkHand.tempBattleInfo.atk) + totalNormalPower;
            atkHand.tempBattleInfo.atk = uint256(temp);
        }
        // Cal defense hand
        isPower0CardIncluded = false;
        totalNormalPower = 0;

        for (uint256 i = 0; i < defHand.tempBattleInfo.inte; i++) {
            uint256 id = defHand.supportCardIds[i];
            PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(id);
            if (card.supportCardType == PepemonCard.SupportCardType.DEFENSE) {
                // Card type is DEFENSE
                // Calc effects of EffectOne array
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCard.EffectOne memory effectOne = card.effectOnes[j];
                    (bool isTriggered, uint256 num) = checkReqCode(atkHand, defHand, effectOne.reqCode, false);
                    if (isTriggered) {
                        if (num > 0) {
                            int256 temp;
                            temp = int256(defHand.tempBattleInfo.def) + effectOne.power * int256(num);
                            defHand.tempBattleInfo.def = uint256(temp);
                            totalNormalPower += effectOne.power * int256(num);
                        } else {
                            int256 temp;
                            temp = int256(defHand.tempBattleInfo.def) + effectOne.power;
                            defHand.tempBattleInfo.def = uint256(temp);
                            totalNormalPower += effectOne.power;
                        }
                    }
                }
            } else if (card.supportCardType == PepemonCard.SupportCardType.STRONG_DEFENSE) {
                // Card type is STRONG DEFENSE
                if (card.unstackable) {
                    bool isNew = true;
                    // Check if card is new to previous cards
                    for (uint256 j = 0; j < i; j++) {
                        if (id == defHand.supportCardIds[j]) {
                            isNew = false;
                            break;
                        }
                    }
                    // Check if card is new to temp support info cards
                    for (uint256 j = 0; j < defHand.tempSupportInfosCount; j++) {
                        if (id == defHand.tempSupportInfos[j].supportCardId) {
                            isNew = false;
                            break;
                        }
                    }
                    if (!isNew) {
                        continue;
                    }
                }
                // Calc effects of EffectOne array
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCard.EffectOne memory effectOne = card.effectOnes[j];
                    (bool isTriggered, uint256 num) = checkReqCode(atkHand, defHand, effectOne.reqCode, false);
                    if (isTriggered) {
                        if (num > 0) {
                            int256 temp;
                            temp = int256(defHand.tempBattleInfo.def) + effectOne.power * int256(num);
                            defHand.tempBattleInfo.def = uint256(temp);
                        } else {
                            if (effectOne.effectTo == PepemonCard.EffectTo.STRONG_DEFENSE) {
                                defHand.tempBattleInfo.def = defHand.tempBattleInfo.sDef;
                                continue;
                            } else if (effectOne.power == 0) {
                                // Equal to the total of all defense cards in the current turn
                                isPower0CardIncluded = true;
                                continue;
                            }
                            int256 temp;
                            temp = int256(defHand.tempBattleInfo.def) + effectOne.power;
                            defHand.tempBattleInfo.def = uint256(temp);
                        }
                    }
                }
                // If card has non-empty effectMany.
                if (card.effectMany.power != 0) {
                    // Add card info to temp support info ids if number of temp support infos did not reach maximu (5) yet.
                    if (defHand.tempSupportInfosCount < 5) {
                        defHand.tempSupportInfos[defHand.tempSupportInfosCount++] = TempSupportInfo({
                            supportCardId: id,
                            effectMany: card.effectMany
                        });
                    }
                }
            } else {
                // Other card type is ignored.
                continue;
            }
        }
        if (isPower0CardIncluded) {
            int256 temp;
            temp = int256(defHand.tempBattleInfo.def) + totalNormalPower;
            defHand.tempBattleInfo.def = uint256(temp);
        }

        return (atkHand, defHand);
    }

    function checkReqCode(
        Hand memory atkHand,
        Hand memory defHand,
        uint256 reqCode,
        bool isAttacker
    ) public view returns (bool, uint256) {
        bool isTriggered = false;
        uint256 num = 0;

        if (reqCode == 0) {
            // No requirement
            isTriggered = true;
        } else if (reqCode == 1) {
            // Intelligence of offense pepemon <= 5.
            isTriggered = (atkHand.tempBattleInfo.inte <= 5 ? true : false);
        } else if (reqCode == 2) {
            // Number of defense cards of defense pepemon is 0.
            isTriggered = true;
            for (uint256 i = 0; i < defHand.tempBattleInfo.inte; i++) {
                PepemonCard.SupportCardType supportCardType = _cardContract.getSupportCardTypeById(
                    defHand.supportCardIds[i]
                );
                if (supportCardType == PepemonCard.SupportCardType.DEFENSE) {
                    isTriggered = false;
                    break;
                }
            }
        } else if (reqCode == 3) {
            // Each +2 offense cards of offense pepemon.
            for (uint256 i = 0; i < atkHand.tempBattleInfo.inte; i++) {
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(atkHand.supportCardIds[i]);
                if (card.supportCardType != PepemonCard.SupportCardType.OFFENSE) {
                    continue;
                }
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCard.EffectOne memory effectOne = card.effectOnes[j];
                    if (effectOne.power == 2) {
                        num++;
                    }
                }
            }
            isTriggered = (num > 0 ? true : false);
        } else if (reqCode == 4) {
            // Each +3 offense cards of offense pepemon.
            for (uint256 i = 0; i < atkHand.tempBattleInfo.inte; i++) {
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(atkHand.supportCardIds[i]);
                if (card.supportCardType != PepemonCard.SupportCardType.OFFENSE) {
                    continue;
                }
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCard.EffectOne memory effectOne = card.effectOnes[j];
                    if (effectOne.power == 3) {
                        num++;
                    }
                }
            }
            isTriggered = (num > 0 ? true : false);
        } else if (reqCode == 5) {
            // Each offense card of offense pepemon.
            for (uint256 i = 0; i < atkHand.tempBattleInfo.inte; i++) {
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(atkHand.supportCardIds[i]);
                if (card.supportCardType != PepemonCard.SupportCardType.OFFENSE) {
                    continue;
                }
                num++;
            }
            isTriggered = (num > 0 ? true : false);
        } else if (reqCode == 6) {
            // Each +3 defense card of defense pepemon.
            for (uint256 i = 0; i < defHand.supportCardIds.length; i++) {
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(defHand.supportCardIds[i]);
                if (card.supportCardType != PepemonCard.SupportCardType.DEFENSE) {
                    continue;
                }
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCard.EffectOne memory effectOne = card.effectOnes[j];
                    if (effectOne.power == 3) {
                        num++;
                    }
                }
            }
            isTriggered = (num > 0 ? true : false);
        } else if (reqCode == 7) {
            // Each +4 defense card of defense pepemon.
            for (uint256 i = 0; i < defHand.supportCardIds.length; i++) {
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(defHand.supportCardIds[i]);
                if (card.supportCardType != PepemonCard.SupportCardType.DEFENSE) {
                    continue;
                }
                for (uint256 j = 0; j < card.effectOnes.length; j++) {
                    PepemonCard.EffectOne memory effectOne = card.effectOnes[j];
                    if (effectOne.power == 4) {
                        num++;
                    }
                }
            }
            isTriggered = (num > 0 ? true : false);
        } else if (reqCode == 8) {
            // Intelligence of defense pepemon <= 5.
            isTriggered = (defHand.tempBattleInfo.inte <= 5 ? true : false);
        } else if (reqCode == 9) {
            // Intelligence of defense pepemon >= 7.
            isTriggered = (defHand.tempBattleInfo.inte >= 7 ? true : false);
        } else if (reqCode == 10) {
            // Offense pepemon is using strong attack
            for (uint256 i = 0; i < atkHand.supportCardIds.length; i++) {
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(atkHand.supportCardIds[i]);
                if (card.supportCardType == PepemonCard.SupportCardType.STRONG_OFFENSE) {
                    isTriggered = true;
                    break;
                }
            }
        } else if (reqCode == 11) {
            // The current HP is less than 50% of max HP.
            if (isAttacker) {
                isTriggered = (
                    atkHand.health * 2 <= int256(_cardContract.getBattleCardById(atkHand.battleCardId).hp)
                        ? true
                        : false
                );
            } else {
                isTriggered = (
                    defHand.health * 2 <= int256(_cardContract.getBattleCardById(defHand.battleCardId).hp)
                        ? true
                        : false
                );
            }
        }
        return (isTriggered, num);
    }
}
