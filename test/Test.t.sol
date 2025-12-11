// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;
import {DeployScript} from "../script/DeployScript.s.sol";
import "../lib/forge-std/src/Test.sol";
import "../src/Roulette.sol";
contract TestScript is Test{
    DeployScript deployScript;
    Roulette rObject;
    uint256 constant INITIAL_BALANCE=1 ether;
    address player1;
    address player2;
    address player3;
    address player4;
    address player5;
    address owner;

    function setUp() public{
        deployScript=new DeployScript();
        (rObject,owner)=deployScript.run();
        
        player1=vm.addr(0x1);
        vm.deal(player1,1 ether);

        player2=vm.addr(0x2);
        vm.deal(player2,1 ether);

        player3=vm.addr(0x3);
        vm.deal(player3,1 ether);

        player4=vm.addr(0x4);
        vm.deal(player4,1 ether);

        player5=vm.addr(0x5);
        vm.deal(player5,1 ether);
    
    }

    function test_randomNumber() external{
        console.log(rObject.currentRandomNumber());
        uint256 rNumber=rObject.generateAndStoreNewRandomNumber();
        console.log(rNumber);
        console.log("Nonce: ", rObject.getNonce());
        vm.warp(block.timestamp + 500); // Advance time by another 500 seconds
        vm.roll(block.number + 5); // Advance block number by another 5
        uint256 newRandomNumber = rObject.generateAndStoreNewRandomNumber();
        console.log("New Random Number: ", newRandomNumber);
        console.log("Updated Nonce: ", rObject.getNonce());

    }

    function test_ownership()external view{
        assert(rObject.owner()==owner);
        console.log("address of rObject",rObject.owner());
        console.log("address Of deployer/owner: ",owner);

    }
    function test_address()external view {
        
        console.log(rObject.owner());
        console.log(player1);
        console.log(player2);
        console.log(player3);
        console.log(player4);
        console.log(player5);

    }


    function test_enterGame()public{
        
        vm.prank(player1);
        vm.expectRevert();
        rObject.enterGame{value:0.01 ether}(78);
        


        vm.prank(player1);
        vm.expectRevert();
        rObject.enterGame{value:0.0001 ether}(11);
        
        vm.prank(player1);
        vm.expectRevert();
        rObject.enterGame{value:0.001 ether}(12);
        
        assert(rObject.currentGameState() == Roulette.CurrentGameState.WaitingForPlayers); // waiting for players when noone entered game
        
        vm.prank(player1);
        rObject.enterGame{value:0.01 ether}(33);

        assert(rObject.currentGameState()== Roulette.CurrentGameState.WaitingForTimeOut); // now current status should be player waiting for timeout untill all five players join or timeout ends

        vm.prank(player1);
        vm.expectRevert(); // revert Player1 already joined
        rObject.enterGame{value:0.01 ether}(21);

        

        Roulette.Player memory playerstruct =rObject.getPlayerInfo(0);
        
        console.log(playerstruct.playerAddress);
        console.log(playerstruct.chosenNumber);
        
        uint256 numberofplayers=rObject.getNumberOfPlayersJoined();
        console.log("Number of Players joined till: ",numberofplayers);
        
        assert(rObject.currentGameState()== Roulette.CurrentGameState.WaitingForTimeOut);
        
        vm.prank(player2);
        rObject.enterGame{value: 0.01 ether}(2);

        assert(rObject.currentGameState() == Roulette.CurrentGameState.WaitingForTimeOut); 

 assert(rObject.currentGameState()== Roulette.CurrentGameState.WaitingForTimeOut);
        
        vm.prank(player3);
        rObject.enterGame{value: 0.01 ether}(8);

        assert(rObject.currentGameState() == Roulette.CurrentGameState.WaitingForTimeOut); 
        
        assert(rObject.currentGameState()== Roulette.CurrentGameState.WaitingForTimeOut);
        
        vm.prank(player4);
        rObject.enterGame{value: 0.01 ether}(30);

        assert(rObject.currentGameState() == Roulette.CurrentGameState.WaitingForTimeOut); 
        

        vm.prank(player5);
        rObject.enterGame{value: 0.01 ether}(30);

        address[] memory winnerAddr=rObject.getWinnersPerRound(1);
        
        for(uint256 i=0;i<winnerAddr.length;i++)
        {
            console.log("addresses of people won",winnerAddr[i]);
        }

        console.log("balance of player 1",player1.balance);
        console.log("balance of player 4",player4.balance);
        console.log("balance of player 5",player5.balance);



        assert(rObject.currentGameState() == Roulette.CurrentGameState.WaitingForPlayers); 

    }
    
    function test_PlayerCanOptForCancelGameAfterMaxJoinWindow() public{
        vm.prank(player1);
        rObject.enterGame{value: 0.01 ether}(4);
        vm.warp(block.timestamp + (6*60));
        rObject.tryAdvanceGame();
        console.log(player1.balance);
    }

    function test_PlayerCannotOptForCancelGameBeforeMaxJoinWindow() public{
        vm.prank(player1);
        rObject.enterGame{value: 0.01 ether}(4);
        
        rObject.tryAdvanceGame();
        console.log(player1.balance);
    }

    function test_PlayersCanOptForSpinIfMinPlayersAvailableAfterMinJoinWindow() public{
        vm.prank(player1);
        rObject.enterGame{value:0.01 ether}(3);
        vm.prank(player2);
        rObject.enterGame{value:0.01 ether}(27);
        vm.warp(block.timestamp + (2*60));
        rObject.tryAdvanceGame();
        console.log(player1.balance);
        console.log(player2.balance);
    }
    function test_PlayersCannotOptForSpinIfMinPlayersAvailableBeforeMinJoinWindow() public{
        vm.prank(player1);
        rObject.enterGame{value:0.01 ether}(3);
        vm.prank(player2);
        rObject.enterGame{value:0.01 ether}(8);
        
        
        console.log(player1.balance);
        console.log(player2.balance);
    }
    function test_noPlayerWon() public{
        vm.prank(player1);
        rObject.enterGame{value:0.01 ether}(3);
        
        vm.prank(player2);
        rObject.enterGame{value:0.01 ether}(8);
        
        vm.prank(player3);
        rObject.enterGame{value:0.01 ether}(26);
        vm.prank(player4);
        rObject.enterGame{value:0.01 ether}(19);
        
        vm.prank(player5);
        rObject.enterGame{value:0.01 ether}(31); // game Automatically starts after 5 players joined
        

        console.log("Player1 balance: ",player1.balance);
        console.log("",player2.balance);
        console.log("",player3.balance);
        console.log("",player4.balance);
        console.log("",player5.balance);
    }

    function test_withdraw()public{
        uint256 initialBalance=address(rObject).balance;
        vm.prank(owner);
        vm.expectRevert(); // should revert no balance in contract cause game is not evaluated
        rObject.withdraw();
        uint256 endBalance=address(rObject).balance;
        console.log("initial balance: ",initialBalance);
        console.log("end balance: ",endBalance);

        vm.prank(player1);
        rObject.enterGame{value:0.01 ether}(3);
        
        vm.prank(player2);
        rObject.enterGame{value:0.01 ether}(8);
        
        vm.prank(player3);
        rObject.enterGame{value:0.01 ether}(26);
        vm.prank(player4);
        rObject.enterGame{value:0.01 ether}(19);
        
        vm.prank(player5);
        rObject.enterGame{value:0.01 ether}(31);

        uint256 gameEndingBalance=address(rObject).balance;
        console.log(gameEndingBalance);
}

}

