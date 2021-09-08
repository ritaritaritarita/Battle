// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
//pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./lib/AdminRole.sol";
import "./IPepemonFactory.sol";
import "./PepemonCardOracle.sol";
import "./lib/Arrays.sol";

contract PepemonCardDeck is ERC721, ERC1155Holder, AdminRole {

    struct Deck {
        uint256 battleCardId;
        uint256 supportCardCount;
        mapping(uint256 => uint) supportCardIds;
    }

    struct SupportCardRequest {
        uint256 supportCardId;
        uint256 amount;
    }

    uint256 public MAX_SUPPORT_CARDS;
//    uint256 public MIN_SUPPORT_CARDS;

    uint256 deckCounter;

    address public battleCardAddress;
    address public supportCardAddress;

    mapping(uint256 => Deck) public decks;
    mapping(address => uint256[]) public playerToDecks;

    constructor() ERC721("Pepedeck", "Pepedeck") {
        MAX_SUPPORT_CARDS = 60;
  //      MIN_SUPPORT_CARDS = 40;
    }

    /**
     * @dev Override supportInterface .
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    // MODIFIERS
    modifier onlyDeckOwner(uint256 _deckId) {
        require(msg.sender == ownerOf(_deckId));
        _;
    }

    function setBattleCardAddress(address _battleCardAddress) public onlyAdmin {
        battleCardAddress = _battleCardAddress;
    }

    function setSupportCardAddress(address _supportCardAddress) public onlyAdmin {
        supportCardAddress = _supportCardAddress;
    }

    function setMaxSupportCards(uint256 _maxSupportCards) public onlyAdmin {
        MAX_SUPPORT_CARDS = _maxSupportCards;
    }

    //function setMinSupportCards(uint256 _minSupportCards) public onlyAdmin {
      //  MIN_SUPPORT_CARDS = _minSupportCards;
    //}

    function createDeck() public {
        deckCounter++;
        _safeMint(msg.sender, deckCounter);
        playerToDecks[msg.sender].push(deckCounter);
    }

    function addBattleCardToDeck(uint256 deckId, uint256 battleCardId) public onlyDeckOwner(deckId) {
        require(
            PepemonFactory(battleCardAddress).balanceOf(msg.sender, battleCardId) >= 1,
            "PepemonCardDeck: Don't own battle card"
        );

        require(battleCardId != decks[deckId].battleCardId, "PepemonCardDeck: Card already in deck");

        //Switch battle cards
        uint256 oldBattleCardId = decks[deckId].battleCardId;
        decks[deckId].battleCardId = battleCardId;

        PepemonFactory(battleCardAddress).safeTransferFrom(msg.sender, address(this), battleCardId, 1, "");

        returnBattleCardFromDeck(oldBattleCardId);
    }

    function removeBattleCardFromDeck(uint256 _deckId) public onlyDeckOwner(_deckId) {
        uint256 oldBattleCardId = decks[_deckId].battleCardId;

        decks[_deckId].battleCardId = 0;

        returnBattleCardFromDeck(oldBattleCardId);
    }

    function addSupportCardsToDeck(uint256 deckId, SupportCardRequest[] memory supportCards) public onlyDeckOwner(deckId){
        for (uint256 i = 0; i < supportCards.length; i++) {
            addSupportCardToDeck(deckId, supportCards[i].supportCardId, supportCards[i].amount);
        }
    }


    //supportCardIndexDescOrder must be in descending order!
    function removeSupportCardsFromDeckOrdered(uint256 deckId, uint[] calldata supportCardIndexDescOrder) public onlyDeckOwner(deckId){
        for (uint256 i = 0; i < supportCardIndexDescOrder.length; i++) {
            removeSupportCardFromDeck(deckId, supportCardIndexDescOrder[i]);
        }
    }

    // INTERNALS
    function addSupportCardToDeck(
        uint256 _deckId,
        uint256 _supportCardId,
        uint256 _amount
    ) internal {
        require(MAX_SUPPORT_CARDS >= decks[_deckId].supportCardCount + (_amount), "PepemonCardDeck: Deck overflow");
        require(
            PepemonFactory(supportCardAddress).balanceOf(msg.sender, _supportCardId) >= _amount,
            "PepemonCardDeck: You don't have enough of this card"
        );

        //Add _amount copies of the card to the deck
        uint tempLen = decks[_deckId].supportCardCount;
        for (uint i = 0; i < _amount; i++){
            decks[_deckId].supportCardIds[tempLen] = _supportCardId;
            tempLen++;
        }
        decks[_deckId].supportCardCount = tempLen;

        PepemonFactory(supportCardAddress).safeTransferFrom(msg.sender, address(this), _supportCardId, _amount, "");
    }

    function removeSupportCardFromDeck(
        uint256 _deckId,
        uint256 supportCardIndex
    ) internal {
        Deck storage deck = decks[_deckId];
        uint tempLen = deck.supportCardCount;
        require(supportCardIndex < tempLen, "ID out of bounds");
        require(tempLen != 0, "DECK_EMPTY");
        uint oldCard = deck.supportCardIds[supportCardIndex];
        deck.supportCardIds[supportCardIndex] = deck.supportCardIds[tempLen-1];
        deck.supportCardIds[tempLen-1] = 0;
        deck.supportCardCount--;
        PepemonFactory(supportCardAddress).safeTransferFrom(address(this), msg.sender, oldCard, 1, "");
    }

    function returnBattleCardFromDeck(uint256 _battleCardId) internal {
        if (_battleCardId != 0) {
            PepemonFactory(battleCardAddress).safeTransferFrom(address(this), msg.sender, _battleCardId, 1, "");
        }
    }

    // VIEWS
    function getBattleCardInDeck(uint256 _deckId) public view returns (uint256) {
        return decks[_deckId].battleCardId;
    }

    function getSupportCardCountInDeck(uint256 _deckId) public view returns (uint256) {
        return decks[_deckId].supportCardCount;
    }

    /**
     * @dev Returns array of support cards for a deck
     * @param _deckId uint256 ID of the deck
     */
    function getAllSupportCardsInDeck(uint256 _deckId) public view returns (uint256[] memory) {
        Deck storage deck = decks[_deckId];
        uint256[] memory supportCards = new uint256[](deck.supportCardCount);
        for (uint256 i = 0; i < deck.supportCardCount; i++) {
            supportCards[_deckId] = deck.supportCardIds[i];
        }
        return supportCards;
    }

    /**
     * @dev Shuffles deck
     * @param _deckId uint256 ID of the deck
     */
    function shuffleDeck(uint256 _deckId, uint256 _seed) public view returns (uint256[] memory) {
        uint256[] memory totalSupportCards = getAllSupportCardsInDeck(_deckId);
        return Arrays.shuffle(totalSupportCards, _seed);
    }
}
