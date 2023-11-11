/** 
 * 𝕺𝖚𝖗 𝕷𝖆𝖉𝖞 𝖔𝖋 𝕻𝖊𝖗𝖕𝖊𝖙𝖚𝖆𝖑 𝕻𝖗𝖔𝖋𝖎𝖙 -> www.ourlady.io |  twitter.com/ourladytoken | https://t.me/ourladytoken
 * @dev OurLadyToken is a community driven, fair launched DeFi Token. Three simple functions occur during each trade: 
 * Reflection, LP Acquisition, & Burn.
 * 
 */


// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

contract OurLady is VRFConsumerBaseV2 {
    mapping(uint => address payable) public lotteryHistory;
    //Chainlink variables
    // The amount of LINK to send with the request
    uint256 internal immutable fee;
    // ID of public key against which randomness is generated
    bytes32 public keyHash;
    uint256 public randomResult;
    VRFCoordinatorV2Interface COORDINATOR;
    LinkTokenInterface LINKTOKEN;

    address vrfCoordinator = ;
    address link_token_contract = ;
    bytes32 keyHash = ;
    uint32 callbackGasLimit = ;
    uint16 requestConfirmations = ;
    uint32 numWords =  ;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    constructor(
        address initialOwner,
        address _vrfCoordinator,
        address _linkToken
    ) VRFConsumerBaseV2(_vrfCoordinator, _linkToken) {
        keyHash = vrfKeyHash;
        //vrfFee the amount of LINK to send with the request
        fee = 0.1 * 10 ** 18; // 0.1 LINK
    }
    // Storage parameters
            uint256[] public s_randomWords;
  uint256 public s_requestId;
  uint64 public s_subscriptionId;
  address s_owner;

  constructor() VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(link_token_contract);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
  }
}

// Layout of Contract ✅
// version ✅
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions
// ✅ This is a comment with a green check mark.
pragma solidity ^0.8.21;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract VRFv2SubscriptionManager is VRFConsumerBaseV2 {
  VRFCoordinatorV2Interface COORDINATOR;
  LinkTokenInterface LINKTOKEN;

  address vrfCoordinator = 0x6168499c0cFfCaCD319c818142124B7A15E857ab;
  address linkTokenContract = 0x01BE23585060835E02B77ef475b0Cc51aA1e0709;
  bytes32 keyHash = 0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc;
  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;
  uint32 numWords =  2;

  // Storage parameters
  uint256[] public s_randomWords;
  uint256 public s_requestId;
  uint64 public s_subscriptionId;
  address s_owner;

  constructor() VRFConsumerBaseV2(vrfCoordinator) {
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    LINKTOKEN = LinkTokenInterface(linkTokenContract);
    s_owner = msg.sender;
  }

  function requestRandomWords() external {
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      numWords
    );
  }

  function fulfillRandomWords(
    uint256, // requestId
    uint256[] memory randomWords
  ) internal override {
    s_randomWords = randomWords;
  }
}

