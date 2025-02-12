// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import "forge-std/console.sol";

contract Quiz {
    struct Quiz_item {
        uint id;
        string question;
        string answer;
        uint min_bet;
        uint max_bet;
    }

    Quiz_item[] public quizList;
    mapping(address => uint256)[] public bets;
    mapping(address => uint256) public claimable;
    address public owner;
    uint public vault_balance;

    constructor() {
        Quiz_item memory q;
        q.id = 1;
        q.question = "1+1=?";
        q.answer = "2";
        q.min_bet = 1 ether;
        q.max_bet = 2 ether;
        addQuiz(q);
    }

    function setOwner(address _newOwner) external {
        require(msg.sender == owner, "NO PERMMION");
        owner = _newOwner;
    }

    function addQuiz(Quiz_item memory q) public {
        require(msg.sender.code.length > 0);
        quizList.push(q);
    }

    function fixAnser(uint256 _fixNum, string memory _newAnswer) external {
        Quiz_item storage q = quizList[_fixNum];
        q.answer = _newAnswer;
    }

    function getAnswer(uint quizId) public view returns (string memory) {
        return quizList[quizId - 1].answer;
    }

    function getQuiz(uint quizId) public returns (Quiz_item memory) {
        if (quizId == 1 || quizId == 2) {
            quizList[quizId - 1].answer = "";
        }
        return quizList[quizId - 1];
    }

    function getQuizNum() public view returns (uint) {
        return quizList.length;
    }

    function betToPlay(uint quizId) public payable {
        if (
            quizList[quizId - 1].min_bet <= msg.value &&
            quizList[quizId - 1].max_bet >= msg.value
        ) {
            quizList[quizId - 1].min_bet + msg.value;
            quizList[quizId - 1].max_bet + msg.value;
            vault_balance += msg.value;
            bets.push();
            if (
                keccak256(abi.encodePacked(quizList[quizId - 1].answer)) ==
                keccak256(abi.encodePacked(""))
            ) {
                quizList[quizId - 1].answer = "OK";
            }

            if (bets[quizId - 1][msg.sender] == 0) {
                bets[quizId - 1][msg.sender] = msg.value;
            } else {
                bets[quizId - 1][msg.sender] += msg.value;
            }
        } else if (
            quizList[quizId - 1].min_bet > msg.value ||
            quizList[quizId - 1].max_bet < msg.value
        ) {
            revert();
        } else {
            revert();
        }
    }

    function solveQuiz(uint quizId, string memory ans) public returns (bool) {
        vault_balance += bets[quizId - 1][msg.sender];
        bets[quizId - 1][msg.sender] = 0;
        claimable[msg.sender] = vault_balance;

        return
            keccak256(abi.encodePacked(quizList[quizId - 1].answer)) ==
            keccak256(abi.encodePacked(ans));
    }

    function claim() public {
        uint256 claimAmount = claimable[msg.sender];
        require(claimAmount > 0);
        claimable[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: claimAmount}("");
        require(success);
    }

    receive() external payable {}
}
