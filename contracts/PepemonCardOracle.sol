// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import './lib/AdminRole.sol';

/**
This contract acts as the oracle, it contains battling information for both the Pepemon Battle and Support cards
**/
contract PepemonCardOracle is AdminRole {

    enum SupportCardType {
        OFFENSE,
        STRONG_OFFENSE,
        DEFENSE,
        STRONG_DEFENSE
    }

    enum EffectTo {
        ATTACK,
        STRONG_ATTACK,
        DEFENSE,
        STRONG_DEFENSE,
        SPEED,
        INTELLIGENCE
    }

    enum EffectFor {
        ME,
        ENEMY
    }

    enum BattleCardTypes{
        FIRE,
        GRASS,
        WATER,
        LIGHTNING,
        WIND,
        POISON,
        GHOST,
        FAIRY,
        EARTH,
        UNKNOWN,
        NONE
    }

    struct BattleCardStats {
        uint256 battleCardId;
        BattleCardTypes element;
        string name;
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
        EffectOne effectOnes;
        EffectMany effectMany;
        // If true, duplicate copies of the card in the same turn will have no extra effect.
        bool unstackable;
        // This property is for EffectMany now.
        // If true, assume the card is already in effect
        // then the same card drawn and used within a number of turns does not extend or reset duration of the effect.
        bool unresettable;
    }

    struct EffectOne {
        // If power is 0, it is equal to the total of all normal offense/defense cards in the current turn.
        
        //basePower = power if req not met
        int256 basePower;

        //triggeredPower = power if req met
        int256 triggeredPower;
        EffectTo effectTo;
        EffectFor effectFor;
        uint256 reqCode; //requirement code
    }

    struct EffectMany {
        int256 power;
        uint256 numTurns;
        EffectTo effectTo;
        EffectFor effectFor;
        uint256 reqCode; //requirement code
    }

    //Struct for keeping track of weakness / resistance
    struct elementWR{
        BattleCardTypes weakness;
        BattleCardTypes resistance;
    }

    

    mapping(uint256 => BattleCardStats) public battleCardStats;
    mapping(uint256 => SupportCardStats) public supportCardStats;
    mapping (BattleCardTypes => string) public elementDecode;
    mapping (BattleCardTypes => elementWR) public weakResist;

    event BattleCardCreated(address sender, uint256 cardId);
    event BattleCardUpdated(address sender, uint256 cardId);
    event SupportCardCreated(address sender, uint256 cardId);
    event SupportCardUpdated(address sender, uint256 cardId);

    constructor(){
        elementDecode[BattleCardTypes.FIRE]="Fire";
        elementDecode[BattleCardTypes.GRASS]="Grass";
        elementDecode[BattleCardTypes.WATER]="Water";
        elementDecode[BattleCardTypes.LIGHTNING]="Lighting";
        elementDecode[BattleCardTypes.WIND]="Wind";
        elementDecode[BattleCardTypes.POISON]="Poison";
        elementDecode[BattleCardTypes.GHOST]="Ghost";
        elementDecode[BattleCardTypes.FAIRY]="Fairy";
        elementDecode[BattleCardTypes.EARTH]="Earth";
        elementDecode[BattleCardTypes.UNKNOWN]="Unknown";
        weakResist[BattleCardTypes.FIRE] = elementWR(BattleCardTypes.WATER,BattleCardTypes.GRASS);
        weakResist[BattleCardTypes.GRASS] = elementWR(BattleCardTypes.FIRE,BattleCardTypes.WATER);
        weakResist[BattleCardTypes.WATER] = elementWR(BattleCardTypes.LIGHTNING,BattleCardTypes.FIRE);
        weakResist[BattleCardTypes.LIGHTNING] = elementWR(BattleCardTypes.EARTH,BattleCardTypes.WIND);
        weakResist[BattleCardTypes.WIND] = elementWR(BattleCardTypes.POISON,BattleCardTypes.EARTH);
        weakResist[BattleCardTypes.POISON] = elementWR(BattleCardTypes.FAIRY,BattleCardTypes.GRASS);
        weakResist[BattleCardTypes.GHOST] = elementWR(BattleCardTypes.FAIRY,BattleCardTypes.POISON);
        weakResist[BattleCardTypes.FAIRY] = elementWR(BattleCardTypes.GHOST,BattleCardTypes.FAIRY);
        weakResist[BattleCardTypes.EARTH] = elementWR(BattleCardTypes.GRASS,BattleCardTypes.GHOST);
        weakResist[BattleCardTypes.UNKNOWN] = elementWR(BattleCardTypes.NONE,BattleCardTypes.NONE);
    }

    function addBattleCard(BattleCardStats memory cardData) public onlyAdmin {
        require(battleCardStats[cardData.battleCardId].battleCardId == 0, "PepemonCard: BattleCard already exists");
        battleCardStats[cardData.battleCardId]=cardData;
        emit BattleCardCreated(msg.sender, cardData.battleCardId);
    }

    function updateBattleCard(BattleCardStats memory cardData) public onlyAdmin {
        require(battleCardStats[cardData.battleCardId].battleCardId != 0, "PepemonCard: BattleCard not found");
        battleCardStats[cardData.battleCardId]=cardData;
        emit BattleCardUpdated(msg.sender, cardData.battleCardId);
    }

    function getBattleCardById(uint256 _id) public view returns (BattleCardStats memory) {
        require(battleCardStats[_id].battleCardId != 0, "PepemonCard: BattleCard not found");
        return battleCardStats[_id];
    }

    function addSupportCard(SupportCardStats memory cardData) public onlyAdmin {
        require(supportCardStats[cardData.supportCardId].supportCardId == 0, "PepemonCard: SupportCard already exists");
        supportCardStats[cardData.supportCardId]=cardData;
        emit SupportCardCreated(msg.sender, cardData.supportCardId);
    }

    function updateSupportCard(SupportCardStats memory cardData) public onlyAdmin {
        require(supportCardStats[cardData.supportCardId].supportCardId != 0, "PepemonCard: SupportCard not found");
        supportCardStats[cardData.supportCardId]=cardData;
        emit SupportCardUpdated(msg.sender, cardData.supportCardId);
    }

    function getSupportCardById(uint256 _id) public view returns (SupportCardStats memory) {
        require(supportCardStats[_id].supportCardId != 0, "PepemonCard: SupportCard not found");
        return supportCardStats[_id];
    }

    function getWeakResist(BattleCardTypes element) public view returns (elementWR memory) {
        return weakResist[element];
    }

    /**
     * @dev Get supportCardType of supportCard
     * @param _id uint256
     */
    function getSupportCardTypeById(uint256 _id) public view returns (SupportCardType) {
        return getSupportCardById(_id).supportCardType;
    }
}
