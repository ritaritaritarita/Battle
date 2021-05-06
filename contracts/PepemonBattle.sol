// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PepemonCardDeck.sol";
import "./PepemonCard.sol";

contract PepemonBattle is Ownable {
    using SafeMath for uint256;

    event BattleCreated(uint256 battleId, address p1, address p2);
    event BattleEnded(uint256 battleId, address winner);

    enum Role {OFFENSE, DEFENSE, PENDING}
    enum TurnHalves {FIRST_HALF, SECOND_HALF}

    struct Battle {
        address p1;
        address p2;
        address winner;
        uint256 battleId;
        uint256 p1DeckId;
        uint256 p2DeckId;
        uint256 createdAt;
        bool isEnded;
        Turn[] turns;
        uint256[] p1SupportCards;
        uint256[] p2SupportCards;
    }

    struct Hand {
        address player;
        TempBattleInfo tempBattleInfo;
        uint256 playedCardCount;
        uint256[] supportCardIds;
        uint256[] tempSupportInfoIds;
        mapping(uint256 => TempSupportInfo) tempSupportInfos;
        Role role;
    }

    struct Turn {
        Hand p1Hand;
        Hand p2Hand;
        TurnHalves turnHalves;
    }

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

    uint256 private _nextBattleId;
    uint8 private _refreshTurn = 5;
    uint256 private _randNonce = 0;

    address private _cardAddress;
    address private _deckAddress;

    PepemonCard private _cardContract;
    PepemonCardDeck private _deckContract;

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
        require(p1 != p2, "PepemonBattle: No Battle yourself");
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
     * @param _battleId uint256 battle id
     */
    function fight(uint256 _battleId) public {
        Battle storage battle = battles[_battleId];
        // battle.p1SupportCards = _deckContract.shuffleDeck(battle.p1DeckId);
        // battle.p2SupportCards = _deckContract.shuffleDeck(battle.p2DeckId);
        _shufflePlayerDeck(_battleId);
        // Make the first turn.
        _makeNewTurn(_battleId);
        // Battle goes!
        while (true) {
            Turn storage lastTurn = battle.turns[battle.turns.length - 1];
            // Resolve role on lastTurn.
            _resolveRole(lastTurn);
            // fight on lastTurn
            _fightInTurn(lastTurn);
            // If battle ended, end battle.
            (bool isEnded, address winner) = _checkIfBattleEnded(lastTurn);
            if (isEnded) {
                battle.winner = winner;
                emit BattleEnded(_battleId, winner);
                break;
            }
            // If the currnet half is first half, go over second half
            // or go over next turn.
            if (lastTurn.turnHalves == TurnHalves.FIRST_HALF) {
                lastTurn.turnHalves = TurnHalves.SECOND_HALF;
            } else {
                if (battle.turns.length / _refreshTurn == 0) {
                    // Refresh players' decks.

                    // Reshuffle decks.
                    battle.p1SupportCards = _deckContract.shuffleDeck(battle.p1DeckId);
                    battle.p2SupportCards = _deckContract.shuffleDeck(battle.p2DeckId);
                    // Refresh battle state
                    // battle.p1PlayedCardCount = 0;
                    // battle.p2PlayedCardCount = 0;
                    lastTurn.p1Hand.playedCardCount = 0;
                    lastTurn.p2Hand.playedCardCount = 0;
                }
                _makeNewTurn(_battleId);
            }
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
     * @param _battleId uint256
     */
    function _makeNewTurn(uint256 _battleId) public {
        Battle storage battle = battles[_battleId];
        bool isTurnsEmpty = (battle.turns.length == 0 ? true : false);
        Turn[] storage turns = battle.turns;
        // Turn storage lastTurn;
        // if (!isTurnsEmpty) {
        //     lastTurn = battle.turns[battle.turns.length - 1];
        // }
        uint256 p1PlayedCardCount = (isTurnsEmpty ? 0 : turns[turns.length - 1].p1Hand.playedCardCount);
        uint256 p2PlayedCardCount = (isTurnsEmpty ? 0 : turns[turns.length - 1].p2Hand.playedCardCount);

        (uint256 p1BattleCardId, ) = _deckContract.decks(battle.p1DeckId);
        (uint256 p2BattleCardId, ) = _deckContract.decks(battle.p2DeckId);
        // Copy battle card stats to temp battle info.
        TempBattleInfo memory p1TempBattleInfo;
        p1TempBattleInfo.battleCardId = _cardContract.getBattleCardById(p1BattleCardId).battleCardId;
        p1TempBattleInfo.spd = _cardContract.getBattleCardById(p1BattleCardId).spd;
        p1TempBattleInfo.inte = _cardContract.getBattleCardById(p1BattleCardId).inte;
        p1TempBattleInfo.def = _cardContract.getBattleCardById(p1BattleCardId).def;
        p1TempBattleInfo.atk = _cardContract.getBattleCardById(p1BattleCardId).atk;
        p1TempBattleInfo.sAtk = _cardContract.getBattleCardById(p1BattleCardId).sAtk;
        p1TempBattleInfo.sDef = _cardContract.getBattleCardById(p1BattleCardId).sDef;

        TempBattleInfo memory p2TempBattleInfo;
        p2TempBattleInfo.battleCardId = _cardContract.getBattleCardById(p2BattleCardId).battleCardId;
        p2TempBattleInfo.spd = _cardContract.getBattleCardById(p2BattleCardId).spd;
        p2TempBattleInfo.inte = _cardContract.getBattleCardById(p2BattleCardId).inte;
        p2TempBattleInfo.def = _cardContract.getBattleCardById(p2BattleCardId).def;
        p2TempBattleInfo.atk = _cardContract.getBattleCardById(p2BattleCardId).atk;
        p2TempBattleInfo.sAtk = _cardContract.getBattleCardById(p2BattleCardId).sAtk;
        p2TempBattleInfo.sDef = _cardContract.getBattleCardById(p2BattleCardId).sDef;

        if (!isTurnsEmpty) {
            // Get temp support info of last turn's hands and calculate their effect for the new turn
            Hand storage p1HandLast = turns[turns.length - 1].p1Hand;
            Hand storage p2HandLast = turns[turns.length - 1].p2Hand;
            p1TempBattleInfo = _calTempSupportOfTurn(p1HandLast, p1TempBattleInfo);
            p2TempBattleInfo = _calTempSupportOfTurn(p2HandLast, p2TempBattleInfo);
            // Copy hp from last turn
            p1TempBattleInfo.hp = turns[turns.length - 1].p1Hand.tempBattleInfo.hp;
            p2TempBattleInfo.hp = turns[turns.length - 1].p2Hand.tempBattleInfo.hp;
        } else {
            // Copy initial hp from battle card
            p1TempBattleInfo.hp = int256(_cardContract.getBattleCardById(p1BattleCardId).hp);
            p2TempBattleInfo.hp = int256(_cardContract.getBattleCardById(p2BattleCardId).hp);
        }
        // Draw support cards by temp battle info inte and speed
        uint256 p1INTE = p1TempBattleInfo.inte;
        uint256[] memory p1SupportCards = new uint256[](p1INTE);
        for (uint256 i = 0; i < p1INTE; i++) {
            p1SupportCards[i] = battle.p1SupportCards[p1PlayedCardCount + i];
        }

        uint256 p2INTE = p2TempBattleInfo.inte;
        uint256[] memory p2SupportCards = new uint256[](p2INTE);
        for (uint256 i = 0; i < p2INTE; i++) {
            p2SupportCards[i] = battle.p2SupportCards[p2PlayedCardCount + i];
        }
        // Make a new turn
        uint256 lastTurnIdx = turns.length;
        turns.push();
        Turn storage turn = turns[lastTurnIdx];
        // Player 1's hand
        turn.p1Hand.player = battle.p1;
        turn.p1Hand.tempBattleInfo = p1TempBattleInfo;
        turn.p1Hand.supportCardIds = p1SupportCards;
        if (!isTurnsEmpty) {
            uint256[] memory tempSupportInfoIds;
            uint256 l = turns.length;
            tempSupportInfoIds = turns[l - 2].p1Hand.tempSupportInfoIds;
            turn.p1Hand.tempSupportInfoIds = tempSupportInfoIds;
            for (uint256 i = 0; i < tempSupportInfoIds.length; i++) {
                turn.p1Hand.tempSupportInfos[i] = turns[l - 2].p1Hand.tempSupportInfos[i];
            }
        }
        turn.p1Hand.playedCardCount = p1PlayedCardCount.add(p1INTE);
        turn.p1Hand.role = Role.PENDING;
        // Player 2's hand
        turn.p2Hand.player = battle.p2;
        turn.p2Hand.tempBattleInfo = p2TempBattleInfo;
        turn.p2Hand.supportCardIds = p2SupportCards;
        if (!isTurnsEmpty) {
            uint256[] memory tempSupportInfoIds;
            uint256 l = turns.length;
            tempSupportInfoIds = turns[l - 2].p2Hand.tempSupportInfoIds;
            turn.p2Hand.tempSupportInfoIds = tempSupportInfoIds;
            for (uint256 i = 0; i < tempSupportInfoIds.length; i++) {
                turn.p2Hand.tempSupportInfos[i] = turns[l - 2].p2Hand.tempSupportInfos[i];
            }
        }
        turn.p2Hand.playedCardCount = p2PlayedCardCount.add(p2INTE);
        turn.p2Hand.role = Role.PENDING;
        turn.turnHalves = TurnHalves.FIRST_HALF;
    }

    /**
     * @dev Cal EffectMany of turn
     * @param _hand Hand
     * @param _tempBattleInfo TempBattleInfo
     */
    function _calTempSupportOfTurn(Hand storage _hand, TempBattleInfo memory _tempBattleInfo)
        private
        returns (TempBattleInfo memory)
    {
        uint256 i = 0;
        uint256[] storage tempSupportInfoIds = _hand.tempSupportInfoIds;
        while (i < tempSupportInfoIds.length) {
            TempSupportInfo storage tempSupportInfo = _hand.tempSupportInfos[i];
            PepemonCard.EffectMany storage effect = tempSupportInfo.effectMany;
            if (effect.numTurns >= 1) {
                if (effect.effectFor == PepemonCard.EffectFor.ME) {
                    // Currently effectTo of EffectMany can be ATTACK, DEFENSE, SPEED and INTELLIGENCE
                    int256 temp;
                    if (effect.effectTo == PepemonCard.EffectTo.ATTACK) {
                        temp = int256(_tempBattleInfo.atk) + effect.power;
                        _tempBattleInfo.atk = uint256(temp);
                    } else if (effect.effectTo == PepemonCard.EffectTo.DEFENSE) {
                        temp = int256(_tempBattleInfo.def) + effect.power;
                        _tempBattleInfo.def = uint256(temp);
                    } else if (effect.effectTo == PepemonCard.EffectTo.SPEED) {
                        temp = int256(_tempBattleInfo.spd) + effect.power;
                        _tempBattleInfo.spd = uint256(temp);
                    } else if (effect.effectTo == PepemonCard.EffectTo.INTELLIGENCE) {
                        temp = int256(_tempBattleInfo.inte) + effect.power;
                        _tempBattleInfo.inte = uint256(temp);
                    }
                } else {
                    // Currently effectFor of EffectMany can be ME so ignored ENEMY
                }
                // Decrease effect numTurns by 1
                effect.numTurns = effect.numTurns.sub(1);
                // Delete this one from tempSupportInfo if the card is no longer available
                if (effect.numTurns == 0) {
                    delete _hand.tempSupportInfos[i];
                    if (i < tempSupportInfoIds.length - 1) {
                        tempSupportInfoIds[i] = tempSupportInfoIds[tempSupportInfoIds.length - 1];
                    }
                    tempSupportInfoIds.pop();
                    continue;
                }
            }
            i++;
        }

        return _tempBattleInfo;
    }

    /**
     * @dev Resolve role in the turn
     * @dev If the turn is in first half, decide roles according to game rule
     * @dev If the turn is in second half, switch roles
     * @param _turn Turn
     */
    function _resolveRole(Turn storage _turn) private {
        uint256 p1BattleCardSpd = _turn.p1Hand.tempBattleInfo.spd;
        uint256 p1BattleCardInte = _turn.p1Hand.tempBattleInfo.inte;
        uint256 p2BattleCardSpd = _turn.p2Hand.tempBattleInfo.spd;
        uint256 p2BattleCardInte = _turn.p2Hand.tempBattleInfo.inte;
        if (_turn.turnHalves == TurnHalves.FIRST_HALF) {
            if (p1BattleCardSpd > p2BattleCardSpd) {
                _turn.p1Hand.role = Role.OFFENSE;
                _turn.p2Hand.role = Role.DEFENSE;
            } else if (p1BattleCardSpd < p2BattleCardSpd) {
                _turn.p1Hand.role = Role.DEFENSE;
                _turn.p2Hand.role = Role.OFFENSE;
            } else {
                if (p1BattleCardInte > p2BattleCardInte) {
                    _turn.p1Hand.role = Role.OFFENSE;
                    _turn.p2Hand.role = Role.DEFENSE;
                } else if (p1BattleCardInte < p2BattleCardInte) {
                    _turn.p1Hand.role = Role.DEFENSE;
                    _turn.p2Hand.role = Role.OFFENSE;
                } else {
                    uint256 rand = _randMod(2);
                    _turn.p1Hand.role = (rand == 0 ? Role.OFFENSE : Role.DEFENSE);
                    _turn.p2Hand.role = (rand == 0 ? Role.DEFENSE : Role.OFFENSE);
                }
            }
        } else {
            _turn.p1Hand.role = (_turn.p1Hand.role == Role.OFFENSE ? Role.DEFENSE : Role.OFFENSE);
            _turn.p2Hand.role = (_turn.p2Hand.role == Role.OFFENSE ? Role.DEFENSE : Role.OFFENSE);
        }
    }

    /**
     * @dev Generate random number in a range
     * @param _modulus uint256
     */
    function _randMod(uint256 _modulus) private returns (uint256) {
        _randNonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _randNonce))) % _modulus;
    }

    /**
     * @dev Check if battle ended
     * @param _turn Turn
     */
    function _checkIfBattleEnded(Turn storage _turn) private view returns (bool, address) {
        if (_turn.p1Hand.tempBattleInfo.hp <= 0) {
            return (true, _turn.p1Hand.player);
        } else if (_turn.p2Hand.tempBattleInfo.hp <= 0) {
            return (true, _turn.p2Hand.player);
        }
        return (false, address(0));
    }

    /**
     * @dev Fight in the last turn.
     * @param turn Turn
     */
    function _fightInTurn(Turn storage turn) private {
        uint256 atkPower;
        uint256 defPower;

        Hand storage p1Hand = turn.p1Hand;
        Hand storage p2Hand = turn.p2Hand;

        _calSupportOfHand(turn, p1Hand);
        _calSupportOfHand(turn, p2Hand);

        if (p1Hand.role == Role.OFFENSE) {
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
     * @param turn Turn
     * @param hand Hand
     */
    function _calSupportOfHand(Turn storage turn, Hand storage hand) private {
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
                        (bool isTriggered, uint256 num) = _checkReqCode(turn, hand, effectOne.reqCode);
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
                        (bool isTriggered, uint256 num) = _checkReqCode(turn, hand, effectOne.reqCode);
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
                        hand.tempSupportInfos[id] = TempSupportInfo({supportCardId: id, effectMany: card.effectMany});
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
                        (bool isTriggered, uint256 num) = _checkReqCode(turn, hand, effectOne.reqCode);
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
                        (bool isTriggered, uint256 num) = _checkReqCode(turn, hand, effectOne.reqCode);
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
                        hand.tempSupportInfos[id] = TempSupportInfo({supportCardId: id, effectMany: card.effectMany});
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
     * @param _turn Turn
     * @param _hand Hand
     * @param _reqCode uint256
     * @return isTriggered(bool) and num(uint256).
     * If isTriggered is true,
     **** If num is 0, checked only condition.
     **** If num is greater than 0, checked effective card numbers.
     * If isTriggered is false, both checking failed.
     */
    function _checkReqCode(
        Turn storage _turn,
        Hand storage _hand,
        uint256 _reqCode
    ) private view returns (bool, uint256) {
        bool isTriggered = false;
        uint256 num = 0;

        if (_reqCode == 0) {
            // No requirement.
            isTriggered = true;
        } else if (_reqCode == 1) {
            // Intelligence of offense pepemon <= 5.
            if (_turn.p1Hand.role == Role.OFFENSE) {
                isTriggered = (_turn.p1Hand.tempBattleInfo.inte <= 5 ? true : false);
            } else {
                isTriggered = (_turn.p2Hand.tempBattleInfo.inte <= 5 ? true : false);
            }
        } else if (_reqCode == 2) {
            // Number of defense cards of defense pepemon is 0.
            isTriggered = true;
            if (_turn.p1Hand.role == Role.DEFENSE) {
                for (uint256 i = 0; i < _turn.p1Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardType supportCardType =
                        _cardContract.getSupportCardTypeById(_turn.p1Hand.supportCardIds[i]);
                    if (supportCardType == PepemonCard.SupportCardType.DEFENSE) {
                        isTriggered = false;
                        break;
                    }
                }
            } else {
                for (uint256 i = 0; i < _turn.p2Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardType supportCardType =
                        _cardContract.getSupportCardTypeById(_turn.p2Hand.supportCardIds[i]);
                    if (supportCardType == PepemonCard.SupportCardType.DEFENSE) {
                        isTriggered = false;
                        break;
                    }
                }
            }
        } else if (_reqCode == 3) {
            // Each +2 offense cards of offense pepemon.
            if (_turn.p1Hand.role == Role.OFFENSE) {
                for (uint256 i = 0; i < _turn.p1Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardStats memory card =
                        _cardContract.getSupportCardById(_turn.p1Hand.supportCardIds[i]);
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
            } else {
                for (uint256 i = 0; i < _turn.p2Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardStats memory card =
                        _cardContract.getSupportCardById(_turn.p2Hand.supportCardIds[i]);
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
            }
            isTriggered = (num > 0 ? true : false);
        } else if (_reqCode == 4) {
            // Each +3 offense cards of offense pepemon.
            if (_turn.p1Hand.role == Role.OFFENSE) {
                for (uint256 i = 0; i < _turn.p1Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardStats memory card =
                        _cardContract.getSupportCardById(_turn.p1Hand.supportCardIds[i]);
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
            } else {
                for (uint256 i = 0; i < _turn.p2Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardStats memory card =
                        _cardContract.getSupportCardById(_turn.p2Hand.supportCardIds[i]);
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
            }
            isTriggered = (num > 0 ? true : false);
        } else if (_reqCode == 5) {
            // Each offense card of offense pepemon.
            if (_turn.p1Hand.role == Role.OFFENSE) {
                for (uint256 i = 0; i < _turn.p1Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardStats memory card =
                        _cardContract.getSupportCardById(_turn.p1Hand.supportCardIds[i]);
                    if (card.supportCardType != PepemonCard.SupportCardType.OFFENSE) {
                        continue;
                    }
                    num++;
                }
            } else {
                for (uint256 i = 0; i < _turn.p2Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardStats memory card =
                        _cardContract.getSupportCardById(_turn.p2Hand.supportCardIds[i]);
                    if (card.supportCardType != PepemonCard.SupportCardType.OFFENSE) {
                        continue;
                    }
                    num++;
                }
            }
            isTriggered = (num > 0 ? true : false);
        } else if (_reqCode == 6) {
            // Each +3 defense card of defense pepemon.
            if (_turn.p1Hand.role == Role.DEFENSE) {
                for (uint256 i = 0; i < _turn.p1Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardStats memory card =
                        _cardContract.getSupportCardById(_turn.p1Hand.supportCardIds[i]);
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
            } else {
                for (uint256 i = 0; i < _turn.p2Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardStats memory card =
                        _cardContract.getSupportCardById(_turn.p2Hand.supportCardIds[i]);
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
            }
            isTriggered = (num > 0 ? true : false);
        } else if (_reqCode == 7) {
            // Each +4 defense card of defense pepemon.
            if (_turn.p1Hand.role == Role.DEFENSE) {
                for (uint256 i = 0; i < _turn.p1Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardStats memory card =
                        _cardContract.getSupportCardById(_turn.p1Hand.supportCardIds[i]);
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
            } else {
                for (uint256 i = 0; i < _turn.p2Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardStats memory card =
                        _cardContract.getSupportCardById(_turn.p2Hand.supportCardIds[i]);
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
            }
            isTriggered = (num > 0 ? true : false);
        } else if (_reqCode == 8) {
            // Intelligence of defense pepemon <= 5.
            if (_turn.p1Hand.role == Role.DEFENSE) {
                isTriggered = (_turn.p1Hand.tempBattleInfo.inte <= 5 ? true : false);
            } else {
                isTriggered = (_turn.p2Hand.tempBattleInfo.inte <= 5 ? true : false);
            }
        } else if (_reqCode == 9) {
            // Intelligence of defense pepemon >= 7.
            if (_turn.p1Hand.role == Role.DEFENSE) {
                isTriggered = (_turn.p1Hand.tempBattleInfo.inte >= 7 ? true : false);
            } else {
                isTriggered = (_turn.p2Hand.tempBattleInfo.inte >= 7 ? true : false);
            }
        } else if (_reqCode == 10) {
            // Offense pepemon is using strong attack
            if (_turn.p1Hand.role == Role.OFFENSE) {
                for (uint256 i = 0; i < _turn.p1Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardStats memory card =
                        _cardContract.getSupportCardById(_turn.p1Hand.supportCardIds[i]);
                    if (card.supportCardType != PepemonCard.SupportCardType.STRONG_OFFENSE) {
                        isTriggered = true;
                        break;
                    }
                }
            } else {
                for (uint256 i = 0; i < _turn.p2Hand.supportCardIds.length; i++) {
                    PepemonCard.SupportCardStats memory card =
                        _cardContract.getSupportCardById(_turn.p2Hand.supportCardIds[i]);
                    if (card.supportCardType != PepemonCard.SupportCardType.STRONG_OFFENSE) {
                        isTriggered = true;
                        break;
                    }
                }
            }
        } else if (_reqCode == 11) {
            // The current HP is less than 50% of max HP.
            isTriggered = (
                _hand.tempBattleInfo.hp * 2 <=
                    int256(_cardContract.getBattleCardById(_hand.tempBattleInfo.battleCardId).hp)
                    ? true
                    : false
            );
        }
        return (isTriggered, num);
    }
}
