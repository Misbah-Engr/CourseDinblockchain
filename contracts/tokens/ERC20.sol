// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BahausheToken is ERC20, Ownable {

    // Maximum number din token da address daya zai iya minting
    uint256 public constant MAX_TOKENS_PER_ADDRESS = 10000 * 10 ** 18;
    uint256 public constant MAX_TOTAL_SUPPLY = 1000000 * 10 ** 18; // 1 million tokens
    // Farashin da za a siyar da tokens: 0.5 Ether ga duk 1000 tokens
    uint256 public constant SELL_BACK_RATE = 0.5 ether;
    uint256 public constant TOKENS_PER_ETHER = 1000 * 10 ** 18; // 1000 tokens per 1 Ether
    // Mapping din da zai tracking number of tokens da kowanne address yayi minting
    mapping(address => uint256) public mintedTokens;

    // error codes da ake kirkira
    error EtherAmountMustBeGreaterThanZero();
    error MintingExceedsMaxAllowedTokens(
        address minter,
        uint256 requested,
        uint256 allowed
    );
    error InsufficientBalance(uint256 requested, uint256 available);
    error InsufficientTokens(uint256 requested, uint256 available);
    error InsufficientContractBalance(uint256 requested, uint256 available);
    error MaxTotalSupplyExceeded(uint256 requested, uint256 available);
    error TransferFailed();

    constructor(
        uint256 initialSupply
    ) ERC20("BahausheToken", "BST") Ownable(msg.sender) {
        _mint(msg.sender, initialSupply);
    }

    // Override the decimals function to ensure 18 decimal places
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    // Function to deposit Ether and mint tokens
    function depositAndMint() external payable {
        if (msg.value == 0) {
            revert EtherAmountMustBeGreaterThanZero();
        }
        // Calculate the number of tokens to mint based on the ether amount
        uint256 tokensToMint = msg.value * TOKENS_PER_ETHER;
        // Check if the minting would exceed the maximum allowed tokens for the sender
        if (mintedTokens[msg.sender] + tokensToMint > MAX_TOKENS_PER_ADDRESS) {
            revert MintingExceedsMaxAllowedTokens(
                msg.sender,
                mintedTokens[msg.sender] + tokensToMint,
                MAX_TOKENS_PER_ADDRESS
            );
        }
        // Check if the minting would exceed the maximum total supply
        if (totalSupply() + tokensToMint > MAX_TOTAL_SUPPLY) {
            revert MaxTotalSupplyExceeded(
                totalSupply() + tokensToMint,
                MAX_TOTAL_SUPPLY
            );
        }
        // Update the minted tokens for the sender
        mintedTokens[msg.sender] += tokensToMint;
        // Mint tokens to the sender
        _mint(msg.sender, tokensToMint);
    }

    // Function to withdraw Ether from the contract,
    // only callable by the owner
    function withdraw(uint256 amount) external onlyOwner {
        uint256 balance = address(this).balance;
        if (amount > balance) {
            revert InsufficientBalance(amount, balance);
        }
        // Transfer the specified amount to the owner
        (bool success, ) = payable(owner()).call{value: amount}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    // Function to sell back tokens and receive Ether
    function sellBack(uint256 amount) external {
        uint256 balance = balanceOf(msg.sender);
        if (amount > balance) {
            revert InsufficientTokens(amount, balance);
        }
        // Calculate the Ether to transfer based on the sell-back rate
        uint256 etherToTransfer = (amount * SELL_BACK_RATE) /
            (TOKENS_PER_ETHER);
        uint256 contractBalance = address(this).balance;
        if (etherToTransfer > contractBalance) {
            revert InsufficientContractBalance(
                etherToTransfer,
                contractBalance
            );
        }
        // Transfer tokens from the sender to the contract using transferFrom
        bool success = transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert TransferFailed();
        }
        // Transfer the Ether to the sender
        (success, ) = payable(msg.sender).call{value: etherToTransfer}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
}
