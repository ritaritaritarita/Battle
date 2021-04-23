// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PepemonCardDeck.sol";
import "./PepemonCard.sol";

contract PepemonBattle is Ownable {
    using SafeMath for uint256;

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
        uint256 p1PlayedCardCount;
        uint256 p2PlayedCardCount;
        uint256 createdAt;
        int256 p1HP;
        int256 p2HP;
        bool isEnded;
        Turn[] turns;
        uint256[] p1SupportCardList;
        uint256[] p2SupportCardList;
    }

    struct PlayerHand {
        address player;
        uint256 battleCardId;
        uint256[] supportCardIdList;
        Role role;
    }

    struct Turn {
        PlayerHand p1Hand;
        PlayerHand p2Hand;
        TurnHalves turnHalves;
    }

    mapping(uint256 => Battle) public battles;

    uint256 nextBattleId;
    uint8 refreshTurn = 5;
    uint256 randNonce = 0;

    address cardAddress;
    address deckAddress;

    PepemonCard cardContract;
    PepemonCardDeck deckContract;

    constructor(address _cardAddress, address _deckAddress) public {
        cardAddress = _cardAddress;
        deckAddress = _deckAddress;
        cardContract = PepemonCard(cardAddress);
        deckContract = PepemonCardDeck(deckAddress);
        nextBattleId = 1;
    }

    /**
     * @dev Set card address
     * @param _cardAddress address
     */
    function setCardAddress(address _cardAddress) public onlyOwner {
        cardAddress = _cardAddress;
        cardContract = PepemonCard(cardAddress);
    }

    /**
     * @dev Set deck address
     * @param _deckAddress address
     */
    function setDeckAddress(address _deckAddress) public onlyOwner {
        deckAddress = _deckAddress;
        deckContract = PepemonCardDeck(deckAddress);
    }

    /**
     * @dev Create battle
     * @param _p1 address player1
     * @param _p2 address player2
     */
    function createBattle(address _p1, address _p2) public onlyOwner {
        require(_p1 != _p2, "No Battle yourself");
        battles[nextBattleId].p1 = _p1;
        battles[nextBattleId].p2 = _p2;
        battles[nextBattleId].winner = address(0);
        battles[nextBattleId].battleId = nextBattleId;
        battles[nextBattleId].p1DeckId = deckContract.playerToDecks(_p1);
        battles[nextBattleId].p2DeckId = deckContract.playerToDecks(_p2);
        battles[nextBattleId].p1PlayedCardCount = 0;
        battles[nextBattleId].p2PlayedCardCount = 0;
        battles[nextBattleId].p1HP = cardContract.getBattleCardById(deckContract.playerToDecks(_p1)).hp;
        battles[nextBattleId].p2HP = cardContract.getBattleCardById(deckContract.playerToDecks(_p2)).hp;
        battles[nextBattleId].createdAt = block.timestamp;
        battles[nextBattleId].isEnded = false;
        nextBattleId = nextBattleId.add(1);
    }

    /**
     * @dev Do battle
     * @param _battleId uint256 battle id
     */
    function battle(uint256 _battleId) public {
        Battle storage battle = battles[_battleId];
        battle.p1SupportCardList = deckContract.getAllSupportCardsInDeck(battle.p1DeckId);
        battle.p2SupportCardList = deckContract.getAllSupportCardsInDeck(battle.p2DeckId);

        while (true) {
            Turn storage lastTurn = battle.turns[battle.turns.length - 1];
            lastTurn = _resolveRole(lastTurn);
            // fight on lastTurn
            _fightInTurn(_battleId, lastTurn);
            // Check if battle ended
            bool isEnded = _checkIfBattleEnded(battle);
            if (isEnded) {
                emit BattleEnded(_battleId, battle.winner);
                break;
            }
            if (lastTurn.turnHalves == TurnHalves.FIRST_HALF) {
                lastTurn.turnHalves = TurnHalves.SECOND_HALF;
            } else {
                _makeNewTurn(_battleId);
            }
        }
    }

    /**
     * @dev Get cards in turn
     * @param _battleId uint256
     */
    function _makeNewTurn(uint256 _battleId) private {
        Battle storage battle = battles[_battleId];
        uint256 p1BattleCardId = deckContract.getDeckById(battle.p1DeckId).battleCardId;
        uint256 p1INTE = cardContract.getBattleCardById(p1BattleCardId).inte;
        uint256[] memory p1SupportCards = new uint256[](p1INTE);
        for (uint256 i = 0; i < p1INTE; i++) {
            p1SupportCards[i] = battle.p1SupportCardList[battle.p1PlayedCardCount + i];
        }
        battle.p1PlayedCardCount = battle.p1PlayedCardCount.add(p1INTE);

        uint256 p2BattleCardId = deckContract.getDeckById(battle.p2DeckId).battleCardId;
        uint256 p2INTE = cardContract.getBattleCardById(p2BattleCardId).inte;
        uint256[] memory p2SupportCards = new uint256[](p2INTE);
        for (uint256 i = 0; i < p2INTE; i++) {
            p2SupportCards[i] = battle.p2SupportCardList[battle.p2PlayedCardCount + i];
        }
        battle.p2PlayedCardCount = battle.p2PlayedCardCount.add(p2INTE);

        battle.turns.push(
            Turn(
                PlayerHand(battle.p1, p1BattleCardId, p1SupportCards, Role.PENDING),
                PlayerHand(battle.p2, p2BattleCardId, p2SupportCards, Role.PENDING),
                TurnHalves.FIRST_HALF
            )
        );
    }

    /**
     * @dev Resolve role in the turn
     * @dev If the turn is in first half, decide roles according to game rule
     * @dev If the turn is in second half, switch roles
     * @param _turn Turn
     */
    function _resolveRole(Turn memory _turn) private returns (Turn memory) {
        uint256 p1BattleCardSpd = cardContract.getBattleCardById(_turn.p1Hand.battleCardId).spd;
        uint256 p1BattleCardInte = cardContract.getBattleCardById(_turn.p1Hand.battleCardId).inte;
        uint256 p2BattleCardSpd = cardContract.getBattleCardById(_turn.p2Hand.battleCardId).spd;
        uint256 p2BattleCardInte = cardContract.getBattleCardById(_turn.p2Hand.battleCardId).inte;
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
        return _turn;
    }

    /**
     * @dev Generate random number in a range
     * @param _modulus uint256
     */
    function _randMod(uint256 _modulus) private returns (uint256) {
        randNonce++;
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))) % _modulus;
    }

    /**
     * @dev Check if battle ended
     * @param _battleId uint256
     */
    function _checkIfBattleEnded(uint256 _battleId) private returns (bool) {
        Battle storage battle = battles[_battleId];
        if (battle.p1HP <= 0) {
            battle.winner = battle.p1;
            return true;
        }
        if (battle.p2HP <= 0) {
            battle.winner = battle.p2;
            return true;
        }
        return false;
    }

    /**
     * @dev Check if battle ended
     * @param _battleId uint256
     * @param _turn Turn
     */
    function _fightInTurn(uint256 _battleId, Turn memory _turn) private {}
}
