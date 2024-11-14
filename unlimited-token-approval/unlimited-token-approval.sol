// SPDX-License-Identifier: MIT
// Find the vuln, write the exploit POC, and how to mitigate
pragma solidity ^0.8.18;

import "forge-std/Test.sol";

contract ContractTest is Test {
    GalacticToken tokenContract;
    address deployer = vm.addr(1);
    address user = vm.addr(2);

    function setUp() public {
        vm.prank(deployer);
        tokenContract = new GalacticToken();
        vm.warp(block.timestamp + 1 hours);
        vm.prank(deployer);
        tokenContract.mint(5000);
    }

    function testTokenOperations() public {
        vm.startPrank(deployer);
        tokenContract.transfer(address(user), 2500);
        vm.stopPrank();
        assertEq(tokenContract.balanceOf(user), 2500, "Initial transfer failed");
        console.log("Test environment initialized successfully");
    }

    receive() external payable {}
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract GalacticToken is IERC20 {
    uint public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    string public name = "GalacticCredit";
    string public symbol = "GLXC";
    uint8 public decimals = 18;
    uint256 private lastMintTime;
    uint256 private constant MINT_COOLDOWN = 1 hours;

    modifier onlyPositive(uint amount) {
        require(amount > 0, "Amount must be positive");
        _;
    }

    function transfer(address recipient, uint amount) external onlyPositive(amount) returns (bool) {
        require(recipient != address(0), "Invalid recipient");
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint amount) external returns (bool) {
        require(spender != address(0), "Invalid spender");
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external onlyPositive(amount) returns (bool) {
        require(recipient != address(0), "Invalid recipient");
        require(balanceOf[sender] >= amount, "Insufficient balance");
        require(allowance[sender][msg.sender] >= amount, "Insufficient allowance");
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint amount) external {
        require(block.timestamp >= lastMintTime + MINT_COOLDOWN, "Minting in cooldown");
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        lastMintTime = block.timestamp;
        emit Transfer(address(0), msg.sender, amount);
    }

    function burn(uint amount) external onlyPositive(amount) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
