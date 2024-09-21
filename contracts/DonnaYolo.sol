// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract DonnaYolo is ERC20, Ownable, ERC20Burnable {

    uint256 public maxTotalSupply = 1_000_000_000 * 10 ** decimals(); // 1 billion tokens
    uint256 public airdropSupply = 400_000_000 * 10 ** decimals(); // 40% for airdrop
    uint256 public liquiditySupply = 200_000_000 * 10 ** decimals(); // 20% for liquidity pool
    uint256 public stakingSupply = 100_000_000 * 10 ** decimals(); // 10% for staking rewards
    uint256 public trendsetterTaxPercentage = 2; // 2% tax on each transaction
    address public stakingContractAddress;

    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => uint256) private _airdropped;

    event TrendsetterTaxCollected(address indexed from, uint256 amount);
    event AirdropClaimed(address indexed claimant, uint256 amount);

    constructor() ERC20("DonnaYolo", "DONYO") {
        _mint(address(this), maxTotalSupply); // Mint all tokens to contract
        _transfer(address(this), owner(), liquiditySupply); // Owner can distribute liquidity
    }

    function claimAirdrop() public {
        require(airdropSupply > 0, "Airdrop supply exhausted");
        require(_airdropped[msg.sender] == 0, "Airdrop already claimed");
        
        uint256 airdropAmount = 1000 * 10 ** decimals(); // Example airdrop per user
        _airdropped[msg.sender] = airdropAmount;
        airdropSupply -= airdropAmount;
        
        _transfer(address(this), msg.sender, airdropAmount);
        emit AirdropClaimed(msg.sender, airdropAmount);
    }

    function setStakingContractAddress(address _stakingContract) external onlyOwner {
        stakingContractAddress = _stakingContract;
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        if (_isExcludedFromFees[sender] || _isExcludedFromFees[recipient]) {
            super._transfer(sender, recipient, amount);
        } else {
            uint256 trendsetterTax = (amount * trendsetterTaxPercentage) / 100;
            uint256 amountAfterTax = amount - trendsetterTax;

            super._transfer(sender, recipient, amountAfterTax);
            super._transfer(sender, address(this), trendsetterTax);

            emit TrendsetterTaxCollected(sender, trendsetterTax);
        }
    }

    function burnCollectedTaxes() external onlyOwner {
        uint256 contractBalance = balanceOf(address(this));
        _burn(address(this), contractBalance); // Burn the collected trendsetter tax
    }

    // Add staking rewards feature (in future development)
    function distributeStakingRewards(address recipient, uint256 amount) external {
        require(msg.sender == stakingContractAddress, "Not authorized");
        require(amount <= stakingSupply, "Not enough staking tokens");

        stakingSupply -= amount;
        _transfer(address(this), recipient, amount);
    }
}
