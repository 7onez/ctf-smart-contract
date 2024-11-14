// SPDX-License-Identifier: MIT
// Find the vuln, write the exploit POC, how to mitigate, and what is the flag
pragma solidity ^0.8.18;

contract AssetVault {
    mapping(address => uint256) private _credits;
    mapping(address => uint8) private _sequence;

    bytes32 private constant PART1 = 0x466c416753776900000000000000000000000000000000000000000000000000;
    bytes32 private constant PART2 = 0x6e62757200000000000000000000000000000000000000000000000000000000;
    bytes32 private constant PART3 = 0x6e65486900000000000000000000000000000000000000000000000000000000;
    bytes32 private constant PART4 = 0x3375504300000000000000000000000000000000000000000000000000000000;

    event BalanceUpdate(bytes32 indexed data, uint256 indexed opcode);
    event TransferLog(bytes32 indexed data, uint256 indexed opcode);

    function enter() public payable {
        require(msg.value >= 0.5 ether, "Min deposit 0.5 ETH");
        _credits[msg.sender] += msg.value;
        
        _sequence[msg.sender] = (_sequence[msg.sender] + 1) % 5;
        
        if (_sequence[msg.sender] == 2) {
            emit BalanceUpdate(PART1 ^ bytes32(block.timestamp), 0xA1);
        }
        if (_sequence[msg.sender] == 3) {
            emit BalanceUpdate(PART2 ^ bytes32(block.timestamp), 0xB2);
        }
    }

    function exit(uint256 _amount) public {
        require(_credits[msg.sender] >= _amount, "Insufficient balance");
        uint8 currentSeq = _sequence[msg.sender];

        (bool success, ) = msg.sender.call{value: _amount}("");
        require(success, "Transfer failed");

        if (_credits[msg.sender] >= _amount) {
            _credits[msg.sender] -= _amount;

            if (currentSeq == 4 && address(this).balance <= 3 ether) {
                emit TransferLog(PART3 ^ bytes32(uint256(uint160(msg.sender))), 0xC3);
            }
            if (address(this).balance <= 1 ether) {
                emit TransferLog(PART4 ^ bytes32(gasleft()), 0xD4);
            }
        }
    }

    function checkBalance(address user) public view returns (uint256) {
        return _credits[user];
    }
}
