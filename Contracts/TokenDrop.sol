// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenDrop is Ownable {
    using SafeMath for uint256;

    IERC20 public token;
    mapping(address => uint256) public claimedTokens;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint256) public allocatedTokens;  // Allocated tokens per address
    bool private _notEntered;

    event TokensClaimed(address indexed recipient, uint256 amount);
    event TokensRemoved(address indexed recipient, uint256 amount);
    event WrongTokensRemoved(address indexed tokenAddress, address indexed to, uint256 amount);

    constructor(address _tokenAddress) {
        token = IERC20(_tokenAddress);
        _notEntered = true;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    function addToWhitelist(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner nonReentrant {
        require(addresses.length == amounts.length, "Addresses and amounts length mismatch");

        for (uint256 i = 0; i < addresses.length; i++) {
            require(amounts[i] > 0, "Token amount must be greater than 0");
            isWhitelisted[addresses[i]] = true;
            allocatedTokens[addresses[i]] = amounts[i];
        }
    }

    function removeFromWhitelist(address[] calldata addresses) external onlyOwner nonReentrant {
        for (uint256 i = 0; i < addresses.length; i++) {
            isWhitelisted[addresses[i]] = false;
            allocatedTokens[addresses[i]] = 0;
        }
    }

    function claimTokens() external nonReentrant {
        require(isWhitelisted[msg.sender], "Address is not whitelisted");
        require(claimedTokens[msg.sender] == 0, "Tokens already claimed");

        uint256 amount = allocatedTokens[msg.sender];
        require(amount > 0, "No tokens allocated to this address");

        claimedTokens[msg.sender] = amount;
        // Use Safe Token Transfer function
        safeTokenTransfer(msg.sender, amount);

        emit TokensClaimed(msg.sender, amount);
    }

    function removeTokens(address _recipient, uint256 _amount) external onlyOwner nonReentrant {
        require(_recipient != address(0), "Invalid recipient address");
        require(_amount > 0, "Token amount must be greater than 0");

        safeTokenTransfer(_recipient, _amount);

        emit TokensRemoved(_recipient, _amount);
    }

    function removeWrongTokens(address _tokenAddress, address _to, uint256 _amount) external onlyOwner nonReentrant {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_to != address(0), "Invalid recipient address");
        require(_amount > 0, "Token amount must be greater than 0");

        IERC20 wrongToken = IERC20(_tokenAddress);
        require(wrongToken.transfer(_to, _amount), "Token transfer failed");

        emit WrongTokensRemoved(_tokenAddress, _to, _amount);
    }

    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= _amount, "Insufficient token balance");

        (bool success, ) = address(token).call(abi.encodeWithSelector(
            token.transfer.selector, _to, _amount
        ));
        require(success, "Token transfer failed");

        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter.add(_amount) == balanceBefore, "Inconsistent token transfer");
    }
}
