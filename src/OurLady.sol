/**
 * 𝕺𝖚𝖗 𝕷𝖆𝖉𝖞 𝖔𝖋 𝕻𝖊𝖗𝖕𝖊𝖙𝖚𝖆𝖑 𝕻𝖗𝖔𝖋𝖎𝖙
 * www.ourlady.io
 * twitter.com/ourladytoken
 * https://t.me/ourladytoken
 * @dev OurLadyToken is an irreverent but ethical and fair-launched hybrid utility/meme Token.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract OurLady is ERC20, ERC20Burnable, Ownable, VRFConsumerBaseV2 {
    constructor(
        address initialOwner,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    )
        ERC20("Our Lady Of Perpetual Profit", "OURLADY")
        Ownable(initialOwner)
        VRFConsumerBaseV2(vrfCoordinatorV2)
    {
        _mint(msg.sender, 10 * 10 ** 27); //10 Billion Tokens
        deploymentTime = block.timestamp;

        // Initialize Uniswap V2 Router
        uniswapV2Router = IUniswapV2Router02(
            0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
        );
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        ourLadyRewardsWallet = payable(msg.sender); // Set to deployer initially

        // VRFConsumerBaseV2 initialization
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;
    }

    /* State variables */

    uint256 public constant MAX_HOLDING = 1e16; // 1% of total supply
    uint256 public constant INITIAL_TAX_RATE = 200; // 2%
    uint256 public constant REDUCED_TAX_RATE = 100; // 1%
    uint256 public constant TAX_REDUCTION_TIME = 30 days;
    uint256 public constant MIN_ETH_BALANCE = 0.2 ether;
    uint256 public constant MINIMUM_LINK_BALANCE = 10 * 10 ** 18; // 10 LINK

    IUniswapV2Router02 uniswapV2Router;
    address public uniswapV2Pair;
    address payable public ourLadyRewardsWallet;
    uint256 public deploymentTime;
    bool public tradingEnabled = false;

    // Chainlink VRF Variables
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    uint64 private immutable i_subscriptionId;
    bytes32 private immutable i_gasLane; // aka 'keyHash'
    uint32 private immutable i_callbackGasLimit;
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 2;
    address private constant LINK_TOKEN =
        0x514910771AF9Ca656af840dff83E8264EcF986CA; //use this if price feed used
    address private constant ETH_LINK_PRICE_FEED =
        0xDC530D9457755926550b59e8ECcdaE7624181557;

    // Lottery Variables
    uint256 private immutable i_interval; // do i need this?
    uint256 private s_lastTimeStamp; // I won't need This?
    address private s_recentWinner;
    address payable[] private s_participants;
    LotteryState private s_lotteryState;
    address[] public participants;

    /* Errors */
    error OurLady__UpkeepNotNeeded(
        uint256 currentEthBalance,
        uint256 currentLinkBalance,
        uint256 numParticipants,
        uint256 lotteryState
    );
    error OurLady__TransferFailed();
    error OurLady__LotteryNotOpen();

    /* Type declarations */
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /* Events */
    event RequestedLotteryWinner(uint256 indexed requestId);
    event LotteryEnter(
        address indexed participant,
        uint256 amount,
        uint256 timestamp
    );
    event WinnerSelected(
        address indexed participant,
        uint256 randomNum,
        uint256 timestamp
    );

    /* Functions */

    function renounceOwnership() public override onlyOwner {
        super.renounceOwnership();
    }

    mapping(address => uint256[]) private addressToIndices;

    function burn(uint256 amount) public override {
        super.burn(amount);
        uint256 entries = amount / 1000;
        for (uint256 i = 0; i < entries; i++) {
            participants.push(msg.sender);
            addressToIndices[msg.sender].push(participants.length - 1);
        }
        emit LotteryEnter(msg.sender, amount, participants.length);
    }

    function getParticipantAt(uint256 index) public view returns (address) {
        require(index < participants.length, "Index out of bounds");
        return participants[index];
    }

    // Function to get a participant's indices and the total length of the s_participants array
    function getParticipantInfo(
        address participant
    ) public view returns (uint256[] memory indices, uint256 totalEntries) {
        return (addressToIndices[participant], participants.length);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        // Check if sender or recipient is the contract itself, the owner, or the Uniswap pair
        bool isExemptFromHoldingLimit = (sender == address(this) ||
            recipient == address(this) ||
            sender == owner() ||
            recipient == owner() ||
            sender == uniswapV2Pair ||
            recipient == uniswapV2Pair);

        if (!isExemptFromHoldingLimit) {
            require(
                balanceOf(recipient) + amount <= MAX_HOLDING,
                "Transfer exceeds maximum holding"
            );
        }

        // Check if sender or recipient is the contract itself or the owner for tax exemption
        bool isTaxExempt = isExemptFromHoldingLimit;

        // Check if this is a Uniswap trade
        bool isUniswapTrade = (sender == uniswapV2Pair ||
            recipient == uniswapV2Pair);

        uint256 tokensToTransfer = amount;

        // Apply tax if it's a Uniswap trade and not tax exempt
        if (isUniswapTrade && !isTaxExempt) {
            uint256 taxAmount = calculateTax(amount);
            tokensToTransfer -= taxAmount;

            if (taxAmount > 0) {
                super._transfer(sender, ourLadyRewardsWallet, taxAmount);
            }
        }

        super._transfer(sender, recipient, tokensToTransfer);
    }

    function setUniswapPairAddress(
        address _uniswapPairAddress
    ) external onlyOwner {
        uniswapV2Pair = _uniswapPairAddress;
    }

    /**
     * @dev This is the function that the Chainlink Keeper nodes call
     * they look for `upkeepNeeded` to return True.
     * the following should be true for this to return true:
     * 1. The time interval has passed between raffle runs.
     * 2. The lottery is open.
     * 3. The contract has ETH.
     * 4. Implicity, your subscription is funded with LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool isOpen = LotteryState.OPEN == s_lotteryState;
        //bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval); I don't think I need this
        bool hasParticipants = s_participants.length > 0;
        bool hasMinimumEth = address(ourLadyRewardsWallet).balance >=
            MIN_ETH_BALANCE;
        bool hasMinimumLink = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789)
            .balanceOf(ourLadyRewardsWallet) >= MINIMUM_LINK_BALANCE;
        upkeepNeeded = (isOpen &&
            hasMinimumEth &&
            hasMinimumLink &&
            hasParticipants);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert OurLady__UpkeepNotNeeded(
                address(ourLadyRewardsWallet).balance,
                IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789).balanceOf(
                    ourLadyRewardsWallet
                ),
                s_participants.length,
                uint256(s_lotteryState)
            );
        }
        if (address(this).balance < MIN_ETH_BALANCE) {
            maintainMinEthBalance();
        }
        if (
            IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789).balanceOf(
                address(this)
            ) < MINIMUM_LINK_BALANCE
        ) {
            maintainMinLinkBalance();
        }
        s_lotteryState = LotteryState.CALCULATING;
        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );

        emit RequestedLotteryWinner(requestId);
    }

    /**
     * @dev This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_participants.length;
        address payable recentWinner = s_participants[indexOfWinner];
        s_recentWinner = recentWinner;
        s_participants = new address payable[](0);
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        emit WinnerSelected(recentWinner, randomWords[0], s_lastTimeStamp);
        uint256 rewardsBalance = balanceOf(ourLadyRewardsWallet);
        uint256 amountToSend = (rewardsBalance * 80) / 100; // 80% of rewards balance, make sure it only transfers the OurLady tokens.
        (bool success, ) = ourLadyRewardsWallet.call{value: amountToSend}(""); // Send 80% of the rewards balance to the WinnerSelected
        // require(success, "Transfer failed");
        if (!success) {
            revert OurLady__TransferFailed();
        }
    }

    function calculateTax(uint256 amount) private view returns (uint256) {
        uint256 taxRate = block.timestamp > deploymentTime + TAX_REDUCTION_TIME
            ? REDUCED_TAX_RATE
            : INITIAL_TAX_RATE;
        return (amount * taxRate) / 10000;
    }

    ////////////////////////////////////
    // Ethereum Maintenance Functions //
    ////////////////////////////////////

    function maintainMinEthBalance() private {
        uint256 contractEthBalance = address(this).balance;
        if (contractEthBalance < MIN_ETH_BALANCE) {
            uint256 ethAmount = (MIN_ETH_BALANCE - contractEthBalance);
            uint256 tokenAmount = calculateEthToSwap(ethAmount);
            swapTokensForExactEth(ethAmount, tokenAmount);
        }
    }

    function calculateTokensToSwap(
        uint256 ethAmount
    ) private view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        // Note: The path is from token to ETH, but we're calculating the amount of tokens needed for a certain amount of ETH,
        // so we need to reverse the amounts returned by getAmountsOut
        uint[] memory amounts = uniswapV2Router.getAmountsIn(ethAmount, path);

        return amounts[0];
    }

    function swapTokensForExactEth(
        uint256 ethAmount,
        uint256 tokenAmount
    ) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapTokensForExactETH(
            ethAmount,
            tokenAmount,
            path,
            address(this),
            block.timestamp
        );
    }

    ////////////////////////////////
    // LINK Maintenance Functions //
    ///////////////////////////////

    function maintainMinLinkBalance() private {
        IERC20 link = IERC20(LINK_TOKEN);
        uint256 contractLinkBalance = link.balanceOf(address(this));
        if (contractLinkBalance < MINIMUM_LINK_BALANCE) {
            uint256 ethAmount = calculateEthToSwap(
                MINIMUM_LINK_BALANCE - contractLinkBalance
            );
            swapEthForExactLink(ethAmount);
        }
    }

    function calculateEthToSwap(
        uint256 linkAmount
    ) private view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            ETH_LINK_PRICE_FEED
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return (linkAmount * uint256(price)) / 10 ** 18;
    }

    function swapEthForExactLink(uint256 ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = LINK_TOKEN;

        // Make sure the contract has enough Ether to perform the swap.
        require(
            address(this).balance >= ethAmount,
            "Not enough Ether in contract for swap"
        );

        uniswapV2Router.swapETHForExactTokens{value: ethAmount}(
            MINIMUM_LINK_BALANCE,
            path,
            address(this),
            block.timestamp
        );
    }

    /** Getter Functions */

    function getLotteryState() public view returns (LotteryState) {
        return s_lotteryState;
    }

    function getNumWords() public pure returns (uint256) {
        return NUM_WORDS;
    }

    function getRequestConfirmations() public pure returns (uint256) {
        return REQUEST_CONFIRMATIONS;
    }

    function getRecentWinner() public view returns (address) {
        return s_recentWinner;
    }

    function getParticipant(uint256 index) public view returns (address) {
        return s_participants[index];
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }

    function getInterval() public view returns (uint256) {
        return i_interval;
    }

    // function getEntranceFee() public view returns (uint256) {
    //     return i_entranceFee;
    // }

    function getNumberOfParticipants() public view returns (uint256) {
        return s_participants.length;
    }
}
