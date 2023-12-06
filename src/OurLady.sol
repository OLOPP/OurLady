/**
 * 𝕺𝖚𝖗 𝕷𝖆𝖉𝖞 𝖔𝖋 𝕻𝖊𝖗𝖕𝖊𝖙𝖚𝖆𝖑 𝕻𝖗𝖔𝖋𝖎𝖙
 * www.ourlady.io
 * twitter.com/ourladytoken
 * https://t.me/ourladytoken
 * OurLadyToken is an irreverent but ethical and fair-launched hybrid Defi/Utility and meme Token.
 */
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.21;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";
import "lib/LinkTokenInterface.sol";

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC20Burnable} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import {IUniswapV2Factory} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import {IUniswapV2Pair} from "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";

contract OurLady is ERC20, ERC20Burnable, Ownable, VRFConsumerBaseV2 {
    /* Errors */
    error OurLady__UpkeepNotNeeded(
        uint256 currentEthBalance,
        uint256 currentLinkBalance,
        uint256 lotteryState,
        bool hasParticipants
    );
    error OurLady__TransferFailed();
    error OurLady__LotteryNotOpen();

    /* Type declarations */
    enum LotteryState {
        OPEN,
        CALCULATING
    }

    /* State variables */

    uint256 public constant MAX_HOLDING = 1e16; // 1% of total supply
    uint256 public constant TAX_RATE = 1; // 1%
    uint256 public immutable deploymentTime;
    uint256 public constant TAX_DURATION = 0 days;
    uint256 public constant MIN_ETH_BALANCE = 0.2 ether;
    uint256 public constant MINIMUM_LINK_BALANCE = 2 * 10 ** 18; // 5 LINK
    address payable public RL80treasuryWallet = payable(address(this)); // Our Lady Rewards Wallet

    IUniswapV2Router02 uniswapV2Router;
    address public uniswapV2Pair;
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

    // Declare LINKTOKEN as an instance of the LINK token contract
    LinkTokenInterface public LINKTOKEN;

    // Lottery Variables

    LotteryState private s_lotteryState;
    address payable[] private s_participants;
    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    event RequestedLotteryWinner(uint256 indexed requestId);

    event LotteryEntry(
        address indexed participant,
        uint256 totalEntries,
        uint256 indexed timestamp,
        uint256 indexPosition // Added field for index position
    );

    event WinnerSelected(
        uint256 indexed winningIndex,
        uint256 indexed winningIndex2,
        uint256 indexed timestamp
    );

    /* Functions */
    constructor(
        address initialOwner,
        uint64 subscriptionId,
        bytes32 gasLane, // keyHash
        uint256 interval,
        uint32 callbackGasLimit,
        address vrfCoordinatorV2
    )
        ERC20("Our Lady", "RL80")
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

        RL80treasuryWallet = payable(msg.sender); // Set to deployer initially

        // VRFConsumerBaseV2 initialization
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
        i_gasLane = gasLane;
        i_interval = interval;
        i_subscriptionId = subscriptionId;
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        i_callbackGasLimit = callbackGasLimit;

        LINKTOKEN = LinkTokenInterface(LINK_TOKEN);
    }

    function enableTrading() public onlyOwner {
        tradingEnabled = true;
    }

    function burn(uint256 amount) public override {
        if (s_lotteryState != LotteryState.OPEN) {
            revert OurLady__LotteryNotOpen();
        }
        super.burn(amount);
        uint256 entries = amount / 1000;
        uint256 indexPosition = s_participants.length;

        for (uint256 i = 0; i < entries; i++) {
            s_participants.push(payable(msg.sender));
            emit LotteryEntry(
                msg.sender,
                amount,
                block.timestamp,
                indexPosition + i
            );
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        // Check if trading is enabled or if the transfer is to the contract itself
        require(
            tradingEnabled || recipient == address(this),
            "Trading is not enabled"
        );

        bool isTaxExempt = (sender == address(this) ||
            recipient == address(this) ||
            sender == owner() ||
            recipient == owner());

        if (!isTaxExempt && recipient != owner()) {
            require(
                balanceOf(recipient) + amount <= MAX_HOLDING,
                "Transfer exceeds maximum holding"
            );
        }

        if (!isTaxExempt && block.timestamp <= deploymentTime + TAX_DURATION) {
            uint256 tax = (amount * TAX_RATE) / 100;
            uint256 amountAfterTax = amount - tax;
            super._transfer(sender, address(this), tax);
            amount = amountAfterTax;
        }

        super._transfer(sender, recipient, amount);
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
     * 1. The time interval has passed between lottery events.
     * 2. The lottery is open.
     * 3. There are partiipants.
     * 4. The contract has ETH and LINK.
     */
    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasMinimumEth = address(RL80treasuryWallet).balance >=
            MIN_ETH_BALANCE;
        bool hasMinimumLink = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789)
            .balanceOf(RL80treasuryWallet) >= MINIMUM_LINK_BALANCE;
        bool isOpen = LotteryState.OPEN == s_lotteryState;
        bool hasParticipants = s_participants.length > 0;
        upkeepNeeded = (timePassed &&
            hasMinimumEth &&
            hasMinimumLink &&
            isOpen &&
            hasParticipants);
        return (upkeepNeeded, "0x0"); // performData is unused.
    }

    /**
     * @dev Once `checkUpkeep` is returning `true`, this function is called
     * and it kicks off a Chainlink VRF call to get a random winner.
     */
    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert OurLady__UpkeepNotNeeded(
                address(RL80treasuryWallet).balance,
                IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789).balanceOf(
                    RL80treasuryWallet
                ),
                uint256(s_lotteryState),
                s_participants.length > 0
            );
        }
        //CHECK IF CONTRACT HAS ENOUGH LINK
        if (address(RL80treasuryWallet).balance < MIN_ETH_BALANCE) {
            maintainMinEthBalance();
        }
        if (
            IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789).balanceOf(
                RL80treasuryWallet
            ) < MINIMUM_LINK_BALANCE
        ) {
            maintainMinLinkBalance();
        }

        // Check and top up Chainlink subscription balance

        if (MINIMUM_LINK_BALANCE < 5) {
            topUpSubscription(5 - MINIMUM_LINK_BALANCE);
        }

        s_lotteryState = LotteryState.CALCULATING;

        uint256 requestId = i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
        // Quiz... is this redundant?
        emit RequestedLotteryWinner(requestId);
    }

    /**
     * This is the function that Chainlink VRF node
     * calls to send the money to the random winner.
     */

    function fulfillRandomWords(
        uint256 /* requestId */,
        uint256[] memory randomWords
    ) internal override {
        uint256 indexOfWinner = randomWords[0] % s_participants.length;
        address payable lotteryWinner = s_participants[indexOfWinner];

        // Get the balance of RL80 tokens held by this contract
        uint256 rewardsBalance = balanceOf(address(this));
        uint256 amountToSend = (rewardsBalance * 80) / 100; // 80% of rewards balance

        // Transfer 80% of the RL80 tokens to the lottery winner
        IERC20 tokenContract = IERC20(RL80treasuryWallet);
        bool success = tokenContract.transfer(lotteryWinner, amountToSend);
        if (!success) {
            revert OurLady__TransferFailed();
        }
        s_participants = new address payable[](0);
        s_lotteryState = LotteryState.OPEN;
        s_lastTimeStamp = block.timestamp;
        emit WinnerSelected(indexOfWinner, randomWords[1], block.timestamp);
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

    // Assumes this contract owns link.
    // 1000000000000000000 = 1 LINK
    function topUpSubscription(uint256 amount) internal onlyOwner {
        LINKTOKEN.transferAndCall(
            address(i_vrfCoordinator),
            amount,
            abi.encode(i_subscriptionId)
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

    function getSubscriptionId() public view returns (uint256) {
        return i_subscriptionId;
    }

    function getLastTimeStamp() public view returns (uint256) {
        return s_lastTimeStamp;
    }
}
