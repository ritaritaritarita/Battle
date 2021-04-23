// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PepemonCard is Ownable {
    enum BattleCardType {PLANT, FIRE}

    enum SupportCardType {OFFENSE, STRONG_OFFENSE, DEFENSE, STRONG_DEFENSE}

    enum EffectTo {ATTACK, STRONG_ATTACK, DEFENSE, STRONG_DEFENSE, SPEED, INTELLIGENCE}

    enum EffectFor {ME, ENEMY}

    struct BattleCardStats {
        uint256 battleCardId;
        BattleCardType battleCardType;
        uint256 hp; // hitpoints
        uint256 spd; // speed
        uint256 inte; // intelligence
        uint256 def; // defense
        uint256 atk; // attack
        uint256 sAtk; // special attack
        uint256 sDef; // special defense
    }

    struct SupportCardStats {
        uint256 supportCardId;
        SupportCardType supportCardType;
        string name;
        EffectTo effectTo;
        EffectFor effectFor;
        int256 effectOfCurrentTurn;
        int256 effectOfNextTurns;
        uint256 numberOfNextTurns;
        uint256 reqCode; //requirement code
    }

    mapping(uint256 => BattleCardStats) public battleCardStats;
    mapping(uint256 => SupportCardStats) public supportCardStats;

    event BattleCardCreated(address sender, uint256 cardId);
    event BattleCardUpdated(address sender, uint256 cardId);
    event SupportCardCreated(address sender, uint256 cardId);
    event SupportCardUpdated(address sender, uint256 cardId);

    constructor() public {}

    function addBattleCard(BattleCardStats memory cardData) public onlyOwner {
        require(battleCardStats[cardData.battleCardId].battleCardId == 0, "BattleCard already exists");

        BattleCardStats storage _card = battleCardStats[cardData.battleCardId];
        _card.battleCardId = cardData.battleCardId;
        _card.hp = cardData.hp;
        _card.spd = cardData.spd;
        _card.inte = cardData.inte;
        _card.def = cardData.def;
        _card.atk = cardData.atk;
        _card.sDef = cardData.sDef;
        _card.sAtk = cardData.sAtk;

        emit BattleCardCreated(msg.sender, cardData.battleCardId);
    }

    function updateBattleCard(BattleCardStats memory cardData) public onlyOwner {
        require(battleCardStats[cardData.battleCardId].battleCardId != 0, "BattleCard not found");

        BattleCardStats storage _card = battleCardStats[cardData.battleCardId];
        _card.hp = cardData.hp;
        _card.battleCardType = cardData.battleCardType;
        _card.spd = cardData.spd;
        _card.inte = cardData.inte;
        _card.def = cardData.def;
        _card.atk = cardData.atk;
        _card.sDef = cardData.sDef;
        _card.sAtk = cardData.sAtk;

        emit BattleCardUpdated(msg.sender, cardData.battleCardId);
    }

    function getBattleCardById(uint256 _id) public view returns (BattleCardStats memory) {
        require(battleCardStats[_id].battleCardId != 0, "BattleCard not found");
        return battleCardStats[_id];
    }

    function addSupportCard(SupportCardStats memory cardData) public onlyOwner {
        require(supportCardStats[cardData.supportCardId].supportCardId == 0, "SupportCard already exists");

        SupportCardStats storage _card = supportCardStats[cardData.supportCardId];
        _card.supportCardId = cardData.supportCardId;
        _card.supportCardType = cardData.supportCardType;
        _card.name = cardData.name;
        _card.effectTo = cardData.effectTo;
        _card.effectFor = cardData.effectFor;
        _card.effectOfCurrentTurn = cardData.effectOfCurrentTurn;
        _card.effectOfNextTurns = cardData.effectOfNextTurns;
        _card.numberOfNextTurns = cardData.numberOfNextTurns;
        _card.reqCode = cardData.reqCode;

        emit SupportCardCreated(msg.sender, cardData.supportCardId);
    }

    function updateSupportCard(SupportCardStats memory cardData) public onlyOwner {
        require(supportCardStats[cardData.supportCardId].supportCardId != 0, "SupportCard not found");

        SupportCardStats storage _card = supportCardStats[cardData.supportCardId];
        _card.supportCardType = cardData.supportCardType;
        _card.name = cardData.name;
        _card.effectTo = cardData.effectTo;
        _card.effectFor = cardData.effectFor;
        _card.effectOfCurrentTurn = cardData.effectOfCurrentTurn;
        _card.effectOfNextTurns = cardData.effectOfNextTurns;
        _card.numberOfNextTurns = cardData.numberOfNextTurns;
        _card.reqCode = cardData.reqCode;

        emit SupportCardCreated(msg.sender, cardData.supportCardId);
    }

    function getSupportCardById(uint256 _id) public view returns (SupportCardStats memory) {
        require(supportCardStats[_id].supportCardId != 0, "SupportCard not found");
        return supportCardStats[_id];
    }
}
