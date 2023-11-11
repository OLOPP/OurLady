// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";

contract OurLadyOfPerpetualProfit is ERC20, Ownable {
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    uint256 public constant MAX_HOLDING = 1e16; // 1% of total supply
    uint256 public constant INITIAL_TAX_RATE = 200; // 2%
    uint256 public constant REDUCED_TAX_RATE = 100; // 1%
    uint256 public constant TAX_REDUCTION_TIME = 30 days;
    uint256 public deploymentTime;

    address payable public ourLadyRewardsWallet;
    uint256 public constant MIN_ETH_BALANCE = 0.15 ether;

    constructor() ERC20("Our Lady of Perpetual Profit", "OurLady") {
        _mint(msg.sender, 1e12 * (10 ** uint256(decimals()))); // 1 trillion tokens
        deploymentTime = block.timestamp;

        // Initialize Uniswap V2 Router
        uniswapV2Router = IUniswapV2Router02(0xUniswapV2RouterAddress);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), uniswapV2Router.WETH());

        ourLadyRewardsWallet = payable(msg.sender); // Set to deployer initially
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(balanceOf(recipient) + amount <= MAX_HOLDING, "Transfer exceeds maximum holding");

        uint256 taxAmount = calculateTax(amount);
        uint256 tokensToTransfer = amount - taxAmount;

        super._transfer(sender, recipient, tokensToTransfer);
        if (taxAmount > 0) {
            super._transfer(sender, ourLadyRewardsWallet, taxAmount);
        }

        maintainMinEthBalance();
    }

    function calculateTax(uint256 amount) private view returns (uint256) {
        uint256 taxRate = block.timestamp > deploymentTime + TAX_REDUCTION_TIME ? REDUCED_TAX_RATE : INITIAL_TAX_RATE;
        return amount * taxRate / 10000;
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function maintainMinEthBalance() public {
        uint256 contractEthBalance = address(this).balance;
        if (contractEthBalance < MIN_ETH_BALANCE) {
            uint256 tokensToSwap = calculateTokensToSwap(MIN_ETH_BALANCE - contractEthBalance);
            swapTokensForEth(tokensToSwap);
        }
    }

    function calculateTokensToSwap(uint256 ethAmount) private view returns (uint256) {
        // Placeholder logic for calculating tokens to swap
        return ethAmount;
    }

    receive() external payable {}
}
