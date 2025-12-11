// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
/**
 * @title Roulette Game
 * @author tushar
 * @notice This contract allows anyone to play a roulette game where players can join by sending minimum entry fee 
 * Spins the wheel or Allow you to spin the wheel when certain conditions are met, This contract uses block fields to generate random number
 * also contain Enum to update and retrieve Current Game State
 */

contract Roulette is Ownable {

    enum CurrentGameState {
        WaitingForPlayers,
        WaitingForTimeOut,
        GameInProgress,
        PayoutComplete
    }
    uint256 nonce = 0;
    uint256 constant ENTRY_FEE = 0.01 ether; // Fixed bet amount
    uint8 constant MAX_PLAYERS = 5;
    uint8 constant MIN_PLAYERS = 2;
    uint8 roundNumber;
    uint8 numberOfPeopleWon;

    mapping(uint8 => address[]) public winnersPerRound;

    mapping(address => bool) public addressToPlayerHasJoined;

    uint256 public currentRandomNumber; // Renamed for clarity
    struct Player {
        address playerAddress;
        uint8 chosenNumber;
    }

    
    Player[] public players;
    CurrentGameState public currentGameState;
    uint256 roundStart_Time;
    uint256 MIN_JOIN_TIME = 2 minutes;
    uint256 MAX_JOIN_TIME = 5 minutes;

    error Roulette__NumberMustBeLessThan34();
    error Roulette__PlayerAlreadyJoined();
    error Roulette__msgvalueMustBeEqualToEntryFee();
    error Roulette__GameNotAcceptingPlayers();
    error Roulette__GameInProgress();
    error Roulette__BecomeAPlayerFirst();

    /**
     * @notice this constructor initializes roundNumber generate a randomnumber at first and sets Current Game State
     * @param _initialOwner  owner of the contract
     */
    constructor(address _initialOwner) Ownable(_initialOwner) {
        currentRandomNumber = generateAndStoreNewRandomNumber();
        roundNumber = 1;
        
        currentGameState = CurrentGameState.WaitingForPlayers;
    }
    /**
     * @notice this function allows player to enter the game by choosing his own number by paying entry fees and updates the Current game state if some conditions satisfies
     * @param _number Choosen Number by player to enter the game with
     */

    function enterGame(uint8 _number) public payable {
        if (_number >= 34) {
            revert Roulette__NumberMustBeLessThan34();
        }
        if (addressToPlayerHasJoined[msg.sender] == true) {
            revert Roulette__PlayerAlreadyJoined();
        }

        
        if (msg.value != ENTRY_FEE) {
            revert Roulette__msgvalueMustBeEqualToEntryFee();
        }

        
        if (
            !(currentGameState == CurrentGameState.WaitingForPlayers ||
                currentGameState == CurrentGameState.WaitingForTimeOut)
        ) {
            revert Roulette__GameNotAcceptingPlayers();
        }

        if (players.length == 0) {
            roundStart_Time = block.timestamp;
            currentGameState = CurrentGameState.WaitingForTimeOut;
        }

        players.push(Player(msg.sender, _number));
        addressToPlayerHasJoined[msg.sender] = true;
        if (players.length == MAX_PLAYERS) {
            tryAdvanceGame();
        }
    }
    /**
     * @notice allows player to play the game after certain conditions satifies, generates Lucky Number, calculates total balance proportional 
     * to players Entry Fee, contract share, distributable amount, calculate number of winners,
     * initiates payout according to number of winners and distributes the amount update Current game state deletes all players 
     * increases roundNumber by 1
     */
    function _spinRoulette() internal {
        
        if (currentGameState == CurrentGameState.GameInProgress) {
            revert Roulette__GameInProgress();
        }
        currentGameState = CurrentGameState.GameInProgress;
        uint8 luckyNumber = uint8(generateAndStoreNewRandomNumber());

        uint256 totalHoldingMoney = address(this).balance;
        uint256 contractShare = (totalHoldingMoney * 30) / 100;
        uint256 distributable = totalHoldingMoney - contractShare;

        uint8 winnersCounter = 0;
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].chosenNumber == luckyNumber) {
                winnersPerRound[roundNumber].push(players[i].playerAddress);
                winnersCounter++;
            }
        }

        if (winnersCounter > 0) {
            uint256 splitedMoney = distributable / winnersCounter;

            for (uint256 i = 0; i < winnersPerRound[roundNumber].length; i++) {
                payable(winnersPerRound[roundNumber][i]).transfer(splitedMoney);
            }
        } else {
            uint256 splitedMoney = distributable / players.length;

            for (uint256 i = 0; i < players.length; i++) {
                payable(players[i].playerAddress).transfer(splitedMoney);
            }
        }

        currentGameState = CurrentGameState.PayoutComplete;
        delete players;
        roundNumber++;
        currentGameState = CurrentGameState.WaitingForPlayers;
    }

    /**
     * @notice this function allows players to use this function only when some conditions 
     * are met which  Advances the game by checking if the conditions 
     * to move ahead with the game are met.
     * Conditions include having the max number of players, or a minimum number of players
     * after a specific time has elapsed.
     */

    function tryAdvanceGame() public {
        
        if (players.length < 1) {
            revert Roulette__BecomeAPlayerFirst();
        }
        if (players.length < 1) {
            require(
                players.length < MIN_PLAYERS &&
                    block.timestamp >= roundStart_Time + MAX_JOIN_TIME,
                "Max join Window time is not reached for One player"
            );
        }
        if (players.length >= 2 && players.length < 5) {
            require(
                players.length >= MIN_PLAYERS &&
                    block.timestamp >= roundStart_Time + MIN_JOIN_TIME,
                "Min Time Not passed yet to Start Game"
            );
        } 

        

        if (players.length == MAX_PLAYERS) {
            _spinRoulette();
        } else if (
            players.length >= MIN_PLAYERS &&
            block.timestamp >= roundStart_Time + MIN_JOIN_TIME
        ) {
            _spinRoulette();
        } else if (
            players.length < MIN_PLAYERS &&
            block.timestamp >= roundStart_Time + MAX_JOIN_TIME
        ) {
            cancelGame();
        }
    }


    /**
     * @dev Generates a new random number using block properties and a nonce. This method is not secure
     * @return uint256  returns generated random number
     */
    function generateAndStoreNewRandomNumber() public  returns (uint256) {
        nonce++;
        // Using block.timestamp, block.prevrandao, and nonce to generate a new random number
        uint256 newRandom = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    block.number,
                    nonce
                )
            )
        );
        currentRandomNumber = newRandom % 34;

        return currentRandomNumber;
    }

    /**
     * @dev Cancels the current game and refunds the players' entry fees
     * @notice this function is uesd internally by advancegame() function which allows players to 
     * advance in game when certain time has elapsed when the maximum join time is reached with too few players.
     */

    function cancelGame() internal {
        for (uint256 i = 0; i < players.length; i++) {
            payable(players[i].playerAddress).transfer(ENTRY_FEE);
        }
        delete players;
        currentGameState = CurrentGameState.WaitingForPlayers;
    }

    function withdraw() external onlyOwner {

        uint256 balance = address(this).balance;

        payable(owner()).transfer(balance);
    }

    /**
     * @notice Returns the details of a player at a specific index in the players array.
     * @param index The index of the player to retrieve.
     * @return Player A struct containing the player's address and chosen number.
     */
    function getPlayerInfo(
        uint256 index
    ) external view returns (Player memory) {
        return players[index];
    }

     /**
     * @notice returns the current number of players that have joined the game until now.
     * @return uint256 The number of players in the current round.
     */
    function getNumberOfPlayersJoined() external view returns (uint256) {
        return players.length;
    }

     /**
     * @notice Returns the current state of the game.
     * @return CurrentGameState The current state of the roulette game.
     */

    function getCurrentgameState() public view returns (CurrentGameState) {
        return currentGameState;
    }

    /**
     * @notice returns the current nonce value used for randomness.
     * @return uint256 The current nonce.
     */
    function getNonce() public view returns (uint256) {
        return nonce;
    }
      /**
     * @notice returns the array of winner addresses for a specific round.
     * @param roundId The ID of the round.
     * @return address[] An array of winner addresses for the specified round.
     */
    function getWinnersPerRound(
        uint8 roundId
    ) public view returns (address[] memory) {
        return winnersPerRound[roundId];
    }
    
}
