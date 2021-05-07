// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PepemonCardDeck.sol";
import "./PepemonCard.sol";
import "hardhat/console.sol";

contract PepemonBattle is Ownable {
    using SafeMath for uint256;

    event BattleCreated(uint256 battleId, address p1, address p2);
    event BattleEnded(uint256 battleId, address winner);

    enum Role {OFFENSE, DEFENSE, PENDING}
    enum TurnHalves {FIRST_HALF, SECOND_HALF}
    enum Attacker {PLAYER_ONE, PLAYER_TWO}

    struct NewBattle {
        Player playerOne;
        Player playerTwo;
        uint256 currentTurn;
        uint256 currentRound;
        Attacker attacker;
    }

    struct Player {
        address playerAddress;
        uint256 deckId;
        Hand hand;
    }

    struct Hand {
        PepemonCard.BattleCardStats battleCard;
        TempBattleInfo battleCardBoosts;
        uint256 playedCardCount;
        uint256[] cards;
    }

    struct Battle {
        address p1;
        address p2;
        address winner;
        uint256 battleId;
        uint256 p1DeckId;
        uint256 p2DeckId;
        uint256 createdAt;
        uint256 endedAt;
        uint256 turns;
        bool isEnded;
        uint256[] p1SupportCards;
        uint256[] p2SupportCards;
        TurnHalves turnHalves;
    }

    // struct Turn {
    //     Hand p1Hand;
    //     Hand p2Hand;
    //     TurnHalves turnHalves;
    // }

    struct TempBattleInfo {
        uint256 battleCardId;
        int256 hp;
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
    mapping(address => Hand) public hands;

    uint256 private _nextBattleId;
    uint8 private _refreshTurn = 5;
    uint256 private _randNonce = 0;

    // todo oracle
    address private _cardAddress;
    address private _deckAddress;

    PepemonCard private _cardContract;
    PepemonCardDeck private _deckContract;

    // todo card address needs to be changed to card oracle address
    constructor(address cardAddress, address deckAddress) public {
        _cardAddress = cardAddress;
        _deckAddress = deckAddress;
        _cardContract = PepemonCard(_cardAddress);
        _deckContract = PepemonCardDeck(_deckAddress);
        _nextBattleId = 1;
    }

    /**
     * @dev Set card address
     * @param cardAddress address
     */
    function setCardAddress(address cardAddress) public onlyOwner {
        _cardAddress = cardAddress;
        _cardContract = PepemonCard(_cardAddress);
    }

    /**
     * @dev Set deck address
     * @param deckAddress address
     */
    function setDeckAddress(address deckAddress) public onlyOwner {
        _deckAddress = deckAddress;
        _deckContract = PepemonCardDeck(_deckAddress);
    }

    /**
     * @dev Create battle
     * @param p1 address player1
     * @param p2 address player2
     */
    function createBattle(address p1, address p2) public onlyOwner {
        require(p1 != p2, "PepemonBattle: Cannot battle yourself");
        battles[_nextBattleId].p1 = p1;
        battles[_nextBattleId].p2 = p2;
        battles[_nextBattleId].winner = address(0);
        battles[_nextBattleId].battleId = _nextBattleId;
        battles[_nextBattleId].p1DeckId = _deckContract.playerToDecks(p1);
        battles[_nextBattleId].p2DeckId = _deckContract.playerToDecks(p2);
        battles[_nextBattleId].createdAt = block.timestamp;
        battles[_nextBattleId].isEnded = false;

        emit BattleCreated(_nextBattleId, p1, p2);
        _nextBattleId = _nextBattleId.add(1);
    }

    // Getters for only unit testing now
    /**
     * @dev Get player1's support cards in battle
     * @param battleId uint256
     */
    function getBattleP1SupportCards(uint256 battleId) public view returns (uint256[] memory) {
        uint256[] memory temp = new uint256[](battles[battleId].p1SupportCards.length);
        for (uint256 i = 0; i < battles[battleId].p1SupportCards.length; i++) {
            temp[i] = battles[battleId].p1SupportCards[i];
        }
        return temp;
    }

    /**
     * @dev Get player2's support cards in battle
     * @param battleId uint256
     */
    function getBattleP2SupportCards(uint256 battleId) public view returns (uint256[] memory) {
        uint256[] memory temp = new uint256[](battles[battleId].p2SupportCards.length);
        for (uint256 i = 0; i < battles[battleId].p2SupportCards.length; i++) {
            temp[i] = battles[battleId].p2SupportCards[i];
        }
        return temp;
    }

    /**
     * @dev Do battle
     * @param battleId uint256 battle id
     */
    function fight(uint256 battleId) public {
        NewBattle memory battle = battles[battleId];
        _shufflePlayerDeck(battleId);
        // Make the first turn.
        _makeNewTurn(battleId);

        uint256 turnsPerRound = _calculateTurnsPerRound(
            battle.playerOne.deckId,
            battle.playerTwo.deckId
        );

        // Battle goes!
        while (true) {
            for (uint256 i = 0; i < turnsPerRound; i++) {
                // Resolve role on lastTurn.
                _resolveRole(battleId);
                // fight on lastTurn
                _fightInTurn(battleId);

                (bool isEnded, address winner) = _checkIfBattleEnded(battle);

                // If battle ended, end battle.
                if (true) {
                    emit BattleEnded(battleId, winner);
                    break;
                }

                // If the current half is first half, go over second half
                // or go over next turn.
                if (battle.currentRound <= turnsPerRound) {
                    // Reshuffle decks.
                    battle.playerOne.hand.cards = _deckContract.shuffleDeck(battle.playerOne.deckId);
                    battle.playerTwo.hand.cards = _deckContract.shuffleDeck(battle.playerTwo.deckId);

                    // Refresh battle state todo not sure we need these
                    //                    hands[battle.p1].playedCardCount = 0;
                    //                    hands[battle.p2].playedCardCount = 0;
                } else {
                    _makeNewTurn(battleId);
                }
            }
            break;
        }
    }

    /**
     * @dev Shuffle players' deck in battle
     * @param battleId uint256
     */
    function _shufflePlayerDeck(uint256 battleId) public {
        Battle storage battle = battles[battleId];
        battle.p1SupportCards = _deckContract.shuffleDeck(battle.p1DeckId);
        battle.p2SupportCards = _deckContract.shuffleDeck(battle.p2DeckId);
    }

    /**
     * @dev Get cards in turn
     * @param battleId uint256
     */
    function _makeNewTurn(uint256 battleId) public {
        //        NewBattle storage battle = battles[battleId];
        //        Hand storage p1Hand = hands[battle.p1];
        //        Hand storage p2Hand = hands[battle.p2];
        //
        //        bool isFirstTurn = (battle.turns == 0 ? true : false);
        //        uint256 p1PlayedCardCount = (isFirstTurn ? 0 : p1Hand.playedCardCount);
        //        uint256 p2PlayedCardCount = (isFirstTurn ? 0 : p2Hand.playedCardCount);
        //
        //        // todo the battle card does not change between rounds so we can persist this somewhere
        //        (uint256 p1BattleCardId,) = _deckContract.decks(battle.p1DeckId);
        //        (uint256 p2BattleCardId,) = _deckContract.decks(battle.p2DeckId);
        //
        //        //        // Copy battle card stats to temp battle info.
        //        TempBattleInfo memory p1TempBattleInfo;
        //
        //        // We can store this in the same place as line 220
        //        p1TempBattleInfo.battleCardId = _cardContract.getBattleCardById(p1BattleCardId).battleCardId;
        //        p1TempBattleInfo.spd = _cardContract.getBattleCardById(p1BattleCardId).spd;
        //        p1TempBattleInfo.inte = _cardContract.getBattleCardById(p1BattleCardId).inte;
        //        p1TempBattleInfo.def = _cardContract.getBattleCardById(p1BattleCardId).def;
        //        p1TempBattleInfo.atk = _cardContract.getBattleCardById(p1BattleCardId).atk;
        //        p1TempBattleInfo.sAtk = _cardContract.getBattleCardById(p1BattleCardId).sAtk;
        //        p1TempBattleInfo.sDef = _cardContract.getBattleCardById(p1BattleCardId).sDef;
        //
        //        TempBattleInfo memory p2TempBattleInfo;
        //        p2TempBattleInfo.battleCardId = _cardContract.getBattleCardById(p2BattleCardId).battleCardId;
        //        p2TempBattleInfo.spd = _cardContract.getBattleCardById(p2BattleCardId).spd;
        //        p2TempBattleInfo.inte = _cardContract.getBattleCardById(p2BattleCardId).inte;
        //        p2TempBattleInfo.def = _cardContract.getBattleCardById(p2BattleCardId).def;
        //        p2TempBattleInfo.atk = _cardContract.getBattleCardById(p2BattleCardId).atk;
        //        p2TempBattleInfo.sAtk = _cardContract.getBattleCardById(p2BattleCardId).sAtk;
        //        p2TempBattleInfo.sDef = _cardContract.getBattleCardById(p2BattleCardId).sDef;
        //
        //        if (!isFirstTurn) {
        //            // Get temp support info of previous turn's hands and calculate their effect for the new turn
        //            p1TempBattleInfo = _calTempSupportOfTurn(battle.p1, p1TempBattleInfo);
        //            p2TempBattleInfo = _calTempSupportOfTurn(battle.p2, p2TempBattleInfo);
        //            // Copy hp from last turn
        //            p1TempBattleInfo.hp = p1Hand.tempBattleInfo.hp;
        //            p2TempBattleInfo.hp = p2Hand.tempBattleInfo.hp;
        //        } else {
        //            // Copy initial hp from battle card
        //            p1TempBattleInfo.hp = int256(_cardContract.getBattleCardById(p1BattleCardId).hp);
        //            p2TempBattleInfo.hp = int256(_cardContract.getBattleCardById(p2BattleCardId).hp);
        //        }
        //        // Draw support cards by temp battle info inte and speed
        //        uint256 p1INTE = p1TempBattleInfo.inte;
        //        uint256[] memory p1SupportCards = new uint256[](p1INTE);
        //        for (uint256 i = 0; i < p1INTE; i++) {
        //            p1SupportCards[i] = battle.p1SupportCards[p1PlayedCardCount + i];
        //        }
        //
        //        uint256 p2INTE = p2TempBattleInfo.inte;
        //        uint256[] memory p2SupportCards = new uint256[](p2INTE);
        //        for (uint256 i = 0; i < p2INTE; i++) {
        //            p2SupportCards[i] = battle.p2SupportCards[p2PlayedCardCount + i];
        //        }
        //        // Make a new turn
        //        p1Hand.tempBattleInfo = p1TempBattleInfo;
        //        p1Hand.supportCardIds = p1SupportCards;
        //        p1Hand.playedCardCount = p1PlayedCardCount.add(p1INTE);
        //        p1Hand.role = Role.PENDING;
        //        // Player 2's hand
        //        p2Hand.tempBattleInfo = p2TempBattleInfo;
        //        p2Hand.supportCardIds = p2SupportCards;
        //        p2Hand.playedCardCount = p2PlayedCardCount.add(p2INTE);
        //        p2Hand.role = Role.PENDING;
        //        battle.turnHalves = TurnHalves.FIRST_HALF;
        //        battle.turns = battle.turns.add(1);
    }

    /**
     * @dev Cal EffectMany of turn
     * @param handAddr address
     * @param tempBattleInfo TempBattleInfo
     */
    function _calTempSupportOfTurn(address handAddr, TempBattleInfo memory tempBattleInfo)
    private
    returns (TempBattleInfo memory)
    {
        //        Hand storage hand = hands[handAddr];
        //        uint256 i = 0;
        //        uint256[] storage tempSupportInfoIds = hand.tempSupportInfoIds;
        //        while (i < tempSupportInfoIds.length) {
        //            TempSupportInfo storage tempSupportInfo = hand.tempSupportInfos[i];
        //            PepemonCard.EffectMany storage effect = tempSupportInfo.effectMany;
        //            if (effect.numTurns >= 1) {
        //                if (effect.effectFor == PepemonCard.EffectFor.ME) {
        //                    // Currently effectTo of EffectMany can be ATTACK, DEFENSE, SPEED and INTELLIGENCE
        //                    int256 temp;
        //                    if (effect.effectTo == PepemonCard.EffectTo.ATTACK) {
        //                        temp = int256(tempBattleInfo.atk) + effect.power;
        //                        tempBattleInfo.atk = uint256(temp);
        //                    } else if (effect.effectTo == PepemonCard.EffectTo.DEFENSE) {
        //                        temp = int256(tempBattleInfo.def) + effect.power;
        //                        tempBattleInfo.def = uint256(temp);
        //                    } else if (effect.effectTo == PepemonCard.EffectTo.SPEED) {
        //                        temp = int256(tempBattleInfo.spd) + effect.power;
        //                        tempBattleInfo.spd = uint256(temp);
        //                    } else if (effect.effectTo == PepemonCard.EffectTo.INTELLIGENCE) {
        //                        temp = int256(tempBattleInfo.inte) + effect.power;
        //                        tempBattleInfo.inte = uint256(temp);
        //                    }
        //                } else {
        //                    // Currently effectFor of EffectMany can be ME so ignored ENEMY
        //                }
        //                // Decrease effect numTurns by 1
        //                effect.numTurns = effect.numTurns.sub(1);
        //                // Delete this one from tempSupportInfo if the card is no longer available
        //                if (effect.numTurns == 0) {
        //                    delete hand.tempSupportInfos[i];
        //                    if (i < tempSupportInfoIds.length - 1) {
        //                        tempSupportInfoIds[i] = tempSupportInfoIds[tempSupportInfoIds.length - 1];
        //                    }
        //                    tempSupportInfoIds.pop();
        //                    continue;
        //                }
        //            }
        //            i++;
        //        }
        //
        //        return tempBattleInfo;
    }

    /**
     * @dev Resolve role in the turn
     * @dev If the turn is in first half, decide roles according to game rule
     * @dev If the turn is in second half, switch roles
     * @param battleId uint256
     */
    function _resolveRole(uint256 battleId) public {
        //        Battle storage battle = battles[battleId];
        //        Hand storage p1Hand = hands[battle.p1];
        //        Hand storage p2Hand = hands[battle.p2];
        //
        //        uint256 p1BattleCardSpd = p1Hand.tempBattleInfo.spd;
        //        uint256 p1BattleCardInte = p1Hand.tempBattleInfo.inte;
        //        uint256 p2BattleCardSpd = p2Hand.tempBattleInfo.spd;
        //        uint256 p2BattleCardInte = p2Hand.tempBattleInfo.inte;
        //        if (battle.turnHalves == TurnHalves.FIRST_HALF) {
        //            if (p1BattleCardSpd > p2BattleCardSpd) {
        //                p1Hand.role = Role.OFFENSE;
        //                p2Hand.role = Role.DEFENSE;
        //            } else if (p1BattleCardSpd < p2BattleCardSpd) {
        //                p1Hand.role = Role.DEFENSE;
        //                p2Hand.role = Role.OFFENSE;
        //            } else {
        //                if (p1BattleCardInte > p2BattleCardInte) {
        //                    p1Hand.role = Role.OFFENSE;
        //                    p2Hand.role = Role.DEFENSE;
        //                } else if (p1BattleCardInte < p2BattleCardInte) {
        //                    p1Hand.role = Role.DEFENSE;
        //                    p2Hand.role = Role.OFFENSE;
        //                } else {
        //                    uint256 rand = _randMod(2);
        //                    p1Hand.role = (rand == 0 ? Role.OFFENSE : Role.DEFENSE);
        //                    p2Hand.role = (rand == 0 ? Role.DEFENSE : Role.OFFENSE);
        //                }
        //            }
        //        } else {
        //            p1Hand.role = (p1Hand.role == Role.OFFENSE ? Role.DEFENSE : Role.OFFENSE);
        //            p2Hand.role = (p2Hand.role == Role.OFFENSE ? Role.DEFENSE : Role.OFFENSE);
        //        }
    }

    /**
     * @dev Generate random number in a range
     * @param modulus uint256
     */
    function _randMod(uint256 modulus) private returns (uint256) {
        // todo needs to connect to chain link
        _randNonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _randNonce))) % modulus;
    }

    /**
     * @dev Check if battle ended
     * @param battleId uint256
     */
    function _checkIfBattleEnded(NewBattle memory battle) private view returns (bool, address) {

        if (battle.playerOne.hand.battleCard.hp <= 0) {
            return (true, battle.playerTwo.playerAddress);
        } else if (battle.playerTwo.hand.battleCard.hp <= 0) {
            return (true, battle.playerOne.playerAddress);
        }

        return (false, address(0));
    }

    /**
     * @dev Fight in the last turn.
     * @param battleId uint256
     */
    function _fightInTurn(NewBattle memory battle) public {
        uint256 atkPower;
        uint256 defPower;

        Hand storage p1Hand = hands[battle.p1];
        Hand storage p2Hand = hands[battle.p2];

        _calSupportOfHand(battle.playerOne.playerAddress);
        _calSupportOfHand(battle.playerTwo.playerAddress);

        if (battle.attacker == Attacker.PLAYER_ONE) {
            atkPower = p1Hand.tempBattleInfo.atk;
            defPower = p2Hand.tempBattleInfo.def;
            if (atkPower > defPower) {
                p2Hand.tempBattleInfo.hp -= int256(atkPower - defPower);
            } else {
                p2Hand.tempBattleInfo.hp -= 1;
            }
        } else {
            atkPower = p2Hand.tempBattleInfo.atk;
            defPower = p1Hand.tempBattleInfo.def;
            if (atkPower > defPower) {
                p1Hand.tempBattleInfo.hp -= int256(atkPower - defPower);
            } else {
                p1Hand.tempBattleInfo.hp -= 1;
            }
        }
    }

    /**
     * @dev Calculate effects of support cards in offense hand.
     * @param handAddr address
     */
    function _calSupportOfHand(address handAddr) private {
        Hand storage hand = hands[handAddr];
        // If this card is included in player's hand, adds an additional power equal to the total of
        // all normal offense/defense cards
        bool isPower0CardIncluded = false;
        // Total sum of normal offense/defense cards
        int256 totalNormalPower = 0;

        if (hand.role == Role.OFFENSE) {
            for (uint256 i = 0; i < hand.supportCardIds.length; i++) {
                uint256 id = hand.supportCardIds[i];
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(id);
                if (card.supportCardType == PepemonCard.SupportCardType.OFFENSE) {
                    // Card type is OFFENSE.
                    // Calc effects of EffectOne array
                    for (uint256 j = 0; j < card.effectOnes.length; j++) {
                        PepemonCard.EffectOne memory effectOne = card.effectOnes[j];
                        (bool isTriggered, uint256 num) = _checkReqCode(handAddr, effectOne.reqCode);
                        if (isTriggered) {
                            if (num > 0) {
                                int256 temp;
                                temp = int256(hand.tempBattleInfo.atk) + effectOne.power * int256(num);
                                hand.tempBattleInfo.atk = uint256(temp);
                                totalNormalPower += effectOne.power * int256(num);
                            } else {
                                int256 temp;
                                temp = int256(hand.tempBattleInfo.atk) + effectOne.power;
                                hand.tempBattleInfo.atk = uint256(temp);
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
                            if (id == hand.supportCardIds[j]) {
                                isNew = false;
                                break;
                            }
                        }
                        // Check if card is new to temp support info cards
                        for (uint256 j = 0; j < hand.tempSupportInfoIds.length; j++) {
                            if (id == hand.tempSupportInfoIds[j]) {
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
                        (bool isTriggered, uint256 num) = _checkReqCode(handAddr, effectOne.reqCode);
                        if (isTriggered) {
                            if (num > 0) {
                                int256 temp;
                                temp = int256(hand.tempBattleInfo.atk) + effectOne.power * int256(num);
                                hand.tempBattleInfo.atk = uint256(temp);
                            } else {
                                if (effectOne.effectTo == PepemonCard.EffectTo.STRONG_ATTACK) {
                                    hand.tempBattleInfo.atk = hand.tempBattleInfo.sAtk;
                                    continue;
                                } else if (effectOne.power == 0) {
                                    // Equal to the total of all offense/defense cards in the current turn
                                    isPower0CardIncluded = true;
                                    continue;
                                }
                                int256 temp;
                                temp = int256(hand.tempBattleInfo.atk) + effectOne.power;
                                hand.tempBattleInfo.atk = uint256(temp);
                            }
                        }
                    }
                    // If card has non-empty effectMany.
                    if (card.effectMany.power != 0) {
                        // Add card info to temp support info ids.
                        hand.tempSupportInfoIds.push(id);
                        hand.tempSupportInfos[id] = TempSupportInfo({supportCardId : id, effectMany : card.effectMany});
                    }
                } else {
                    // Other card type is ignored.
                    continue;
                }
            }
            if (isPower0CardIncluded) {
                int256 temp;
                temp = int256(hand.tempBattleInfo.atk) + totalNormalPower;
                hand.tempBattleInfo.atk = uint256(temp);
            }
        } else if (hand.role == Role.DEFENSE) {
            for (uint256 i = 0; i < hand.supportCardIds.length; i++) {
                uint256 id = hand.supportCardIds[i];
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(id);
                if (card.supportCardType == PepemonCard.SupportCardType.DEFENSE) {
                    // Card type is DEFENSE.
                    // Calc effects of EffectOne array
                    for (uint256 j = 0; j < card.effectOnes.length; j++) {
                        PepemonCard.EffectOne memory effectOne = card.effectOnes[j];
                        (bool isTriggered, uint256 num) = _checkReqCode(handAddr, effectOne.reqCode);
                        if (isTriggered) {
                            if (num > 0) {
                                int256 temp;
                                temp = int256(hand.tempBattleInfo.def) + effectOne.power * int256(num);
                                hand.tempBattleInfo.def = uint256(temp);
                                totalNormalPower += effectOne.power * int256(num);
                            } else {
                                int256 temp;
                                temp = int256(hand.tempBattleInfo.def) + effectOne.power;
                                hand.tempBattleInfo.def = uint256(temp);
                                totalNormalPower += effectOne.power;
                            }
                        }
                    }
                } else if (card.supportCardType == PepemonCard.SupportCardType.STRONG_DEFENSE) {
                    // Card type is STRONG DEFENSE.
                    if (card.unstackable) {
                        bool isNew = true;
                        // Check if card is new to previous cards
                        for (uint256 j = 0; j < i; j++) {
                            if (id == hand.supportCardIds[j]) {
                                isNew = false;
                                break;
                            }
                        }
                        // Check if card is new to temp support info cards
                        for (uint256 j = 0; j < hand.tempSupportInfoIds.length; j++) {
                            if (id == hand.tempSupportInfoIds[j]) {
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
                        (bool isTriggered, uint256 num) = _checkReqCode(handAddr, effectOne.reqCode);
                        if (isTriggered) {
                            if (num > 0) {
                                int256 temp;
                                temp = int256(hand.tempBattleInfo.def) + effectOne.power * int256(num);
                                hand.tempBattleInfo.def = uint256(temp);
                            } else {
                                if (effectOne.effectTo == PepemonCard.EffectTo.STRONG_ATTACK) {
                                    hand.tempBattleInfo.def = hand.tempBattleInfo.sDef;
                                    continue;
                                } else if (effectOne.power == 0) {
                                    // Equal to the total of all offense/defense cards in the current turn
                                    isPower0CardIncluded = true;
                                    continue;
                                }
                                int256 temp;
                                temp = int256(hand.tempBattleInfo.def) + effectOne.power;
                                hand.tempBattleInfo.def = uint256(temp);
                            }
                        }
                    }
                    // If card has non-empty effectMany.
                    if (card.effectMany.power != 0) {
                        // Add card info to temp support info ids.
                        hand.tempSupportInfoIds.push(id);
                        hand.tempSupportInfos[id] = TempSupportInfo({supportCardId : id, effectMany : card.effectMany});
                    }
                } else {
                    // Other card type is ignored.
                    continue;
                }
            }
            if (isPower0CardIncluded) {
                int256 temp;
                temp = int256(hand.tempBattleInfo.def) + totalNormalPower;
                hand.tempBattleInfo.def = uint256(temp);
            }
        }
    }

    /**
     * @dev Check requirement code.
     * @param handAddr address
     * @param reqCode uint256
     * @return isTriggered(bool) and num(uint256).
     * If isTriggered is true,
     **** If num is 0, checked only condition.
     **** If num is greater than 0, checked effective card numbers.
     * If isTriggered is false, both checking failed.
     */
    function _checkReqCode(address handAddr, uint256 reqCode) private view returns (bool, uint256) {
        bool isTriggered = false;
        uint256 num = 0;
        Hand storage hand = hands[handAddr];

        if (reqCode == 0) {
            // No requirement.
            isTriggered = true;
        } else if (reqCode == 1) {
            // Intelligence of offense pepemon <= 5.
            isTriggered = (hand.tempBattleInfo.inte <= 5 ? true : false);
        } else if (reqCode == 2) {
            // Number of defense cards of defense pepemon is 0.
            isTriggered = true;
            for (uint256 i = 0; i < hand.supportCardIds.length; i++) {
                PepemonCard.SupportCardType supportCardType =
                _cardContract.getSupportCardTypeById(hand.supportCardIds[i]);
                if (supportCardType == PepemonCard.SupportCardType.DEFENSE) {
                    isTriggered = false;
                    break;
                }
            }
        } else if (reqCode == 3) {
            // Each +2 offense cards of offense pepemon.
            for (uint256 i = 0; i < hand.supportCardIds.length; i++) {
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(hand.supportCardIds[i]);
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
            for (uint256 i = 0; i < hand.supportCardIds.length; i++) {
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(hand.supportCardIds[i]);
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
            for (uint256 i = 0; i < hand.supportCardIds.length; i++) {
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(hand.supportCardIds[i]);
                if (card.supportCardType != PepemonCard.SupportCardType.OFFENSE) {
                    continue;
                }
                num++;
            }
            isTriggered = (num > 0 ? true : false);
        } else if (reqCode == 6) {
            // Each +3 defense card of defense pepemon.
            for (uint256 i = 0; i < hand.supportCardIds.length; i++) {
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(hand.supportCardIds[i]);
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
            for (uint256 i = 0; i < hand.supportCardIds.length; i++) {
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(hand.supportCardIds[i]);
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
            isTriggered = (hand.tempBattleInfo.inte <= 5 ? true : false);
        } else if (reqCode == 9) {
            // Intelligence of defense pepemon >= 7.
            isTriggered = (hand.tempBattleInfo.inte >= 7 ? true : false);
        } else if (reqCode == 10) {
            // Offense pepemon is using strong attack
            for (uint256 i = 0; i < hand.supportCardIds.length; i++) {
                PepemonCard.SupportCardStats memory card = _cardContract.getSupportCardById(hand.supportCardIds[i]);
                if (card.supportCardType != PepemonCard.SupportCardType.STRONG_OFFENSE) {
                    isTriggered = true;
                    break;
                }
            }
        } else if (reqCode == 11) {
            // The current HP is less than 50% of max HP.
            isTriggered = (
            hand.tempBattleInfo.hp * 2 <=
            int256(_cardContract.getBattleCardById(hand.tempBattleInfo.battleCardId).hp)
            ? true
            : false
            );
        }
        return (isTriggered, num);
    }


    /**
        @dev Check the maximum number of turns that can be played each round, to do this we divide the smallest deck
        size with the the largest hand size

        @param _deckOne uint256
        @param _deckTwo uint256
        @return _turns uint256
     */
    function _calculateTurnsPerRound(uint256 _deckOne, uint256 _deckTwo) public view returns (uint256 _turns) {
        (uint256 playerOneBattleCardId, uint256 playerOneCardCount) = _deckContract.decks(_deckOne);
        (uint256 playerTwoBattleCardId,uint256 playerTwoCardCount) = _deckContract.decks(_deckTwo);

        uint256 playerOneHandSize = _cardContract.getBattleCardById(playerOneBattleCardId).inte;
        uint256 playerTwoHandSize = _cardContract.getBattleCardById(playerTwoBattleCardId).inte;

        uint256 smallestDeckSize = playerOneCardCount > playerTwoCardCount ? playerTwoCardCount : playerOneCardCount;
        uint256 largestHandSize = playerOneHandSize > playerTwoHandSize ? playerOneHandSize : playerTwoHandSize;

        return smallestDeckSize / largestHandSize;
    }

    function _constructBattle(uint256 _deckOne, uint256 _deckTwo) public view returns (NewBattle memory _battle) {
        PepemonCardDeck.Deck memory playerOneDeck = _deckContract.decks(_deckOne);
        PepemonCardDeck.Deck memory playerTwoDeck = _deckContract.decks(_deckTwo);

        Player memory playerOne = Player({
        playerAddress : msg.sender,
        deckId : _deckOne,
        hand : Hand({
        battleCard : _cardContract.getBattleCardById(playerOneDeck.battleCardId),
        playerCardCount : playerOneDeck.supportCardCount
        })
        });

        Player memory playerTwo = Player({
        playerAddress : msg.sender,
        deckId : _deckTwo,
        hand : Hand({
        battleCard : _cardContract.getBattleCardById(playerTwoDeck.battleCardId),
        playerCardCount : playerTwoDeck.supportCardCount
        })
        });

        NewBattle memory battle = NewBattle({
        playerOne : playerOne,
        playerTwo : playerTwo,
        currentTurn : 1,
        currentRound : 1,
        attacker : Attacker.PLAYER_ONE
        });

        return battle;
    }
}
