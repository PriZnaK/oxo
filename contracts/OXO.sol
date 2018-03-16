pragma solidity 0.4.19;

contract OXO {
    address public owner;
    uint gameTimeOut = 60*60; //in seconds

    enum GameStatus { New, Started, Finished }
    struct Game {
        address player1;
        address player2;
        uint betValue;
        address currentPlayer;
        uint currentTime;
        GameStatus status;
        address winnerPlayer;
        mapping(address => uint8[]) moves;
    }

    Game[] public games;

    uint8[3][] private winCombinations = [
        [1, 2, 3], [4, 5, 6], [7, 8, 9], [1, 4, 7], 
        [2, 5, 8], [3, 6, 9], [1, 5, 9], [3, 5, 7]
    ];

    event GameCreated(uint gameId, address by, uint betValue);
    event GameStarted(uint gameId, address player1, address player2, uint betValue);
    event GameFinished(uint gameId);
    event GameCanceled(uint gameId);
    event Move(uint gameId, address player, uint8 fieldNumber);
    event RewardPayed(uint gameId, address to, uint amount);
    event Message(string message);

    function OXO() public {
        owner = msg.sender;
    }

    function createGame() payable public returns(uint) {
        require(msg.value > 0);
        // create a new game
        Game memory newGame;
        newGame.player1 = msg.sender;
        newGame.betValue = msg.value;
        newGame.status = GameStatus.New;

        // save the game to games array
        var gameId = games.push(newGame) - 1;
        
        //fire an event
        GameCreated(gameId, msg.sender, msg.value);
        return gameId;
    }

    function joinGame(uint gameId) payable public returns(bool) {
        require(games[gameId].player1 != msg.sender);
        require(games[gameId].status == GameStatus.New);
        require(games[gameId].betValue == msg.value);

        games[gameId].player2 = msg.sender;
        games[gameId].currentPlayer = games[gameId].player1;
        games[gameId].currentTime = block.timestamp;
        games[gameId].status = GameStatus.Started;

        GameStarted(gameId, games[gameId].player1, games[gameId].player2, games[gameId].betValue);

        return true;
    }

    function makeMove(uint gameId, uint8 fieldNumber) public returns(bool) {
        require(fieldNumber >= 1 && fieldNumber <= 9);
        require(games[gameId].currentPlayer == msg.sender);
        require(games[gameId].status == GameStatus.New || games[gameId].status == GameStatus.Started);

        // check if a field is taken
        if (!isMoveUnique(gameId, fieldNumber)) {
            Message("This field is already taken.");
            return false;
        }

        // add move
        games[gameId].moves[msg.sender].push(fieldNumber);
        games[gameId].currentTime = block.timestamp;
        //emit event
        Move(gameId, msg.sender, fieldNumber);
        //calculate game after this move
        checkGame(gameId);

        //if the game is not finished - continue
        if (games[gameId].status != GameStatus.Finished) {
            games[gameId].currentPlayer = games[gameId].player1 == msg.sender ? games[gameId].player2 : games[gameId].player1;
        } else {
            payReward(gameId);
            GameFinished(gameId);
        }

        return true;
    }

    function gameStatus(uint gameId) constant public returns(GameStatus status, address currentPlayer, address winnerPlayer, uint8[] player1moves, uint8[] player2moves) {
        return (
            games[gameId].status, 
            games[gameId].currentPlayer, 
            games[gameId].winnerPlayer, 
            games[gameId].moves[games[gameId].player1],
            games[gameId].moves[games[gameId].player2]
        );
    }

    function cancelGame(uint gameId) public returns(bool) {
        require(games[gameId].player1 == msg.sender || games[gameId].player2 == msg.sender);
        require(games[gameId].currentPlayer != msg.sender);
        require(games[gameId].status != GameStatus.Finished);
        require(games[gameId].currentTime + gameTimeOut > block.timestamp);

        games[gameId].status = GameStatus.Finished;
        games[gameId].winnerPlayer = msg.sender;
        payReward(gameId);

        GameCanceled(gameId);
        
        return true;
    } 

    function isMoveUnique(uint gameId, uint fieldNumber) constant private returns(bool) {
        Game storage game = games[gameId];
        // check player1 moves
        for (uint i = 0; i < game.moves[game.player1].length; i++) {
            if (game.moves[game.player1][i] == fieldNumber)
                return false;
        }
        // check player2 moves
        for (uint j = 0; j < game.moves[game.player2].length; j++) {
            if (game.moves[game.player2][j] == fieldNumber)
                return false;
        }
        return true;
    }

    function checkGame(uint gameId) private {
        Game storage game = games[gameId];
        // no sence calculate game if players not have 3 moves
        if (game.moves[game.player1].length < 3) 
            return;

        // check if one of winConbinations has players moves
        for (uint a = 0; a < winCombinations.length; a++) {
            uint combCount = 0;
            for (uint b = 0; b < 3; b++) {
                for (uint i = 0; i < game.moves[game.currentPlayer].length; i++) {
                    if (game.moves[game.currentPlayer][i] == winCombinations[a][b]) {
                        combCount++;
                        break;
                    }
                }
            }
            if (combCount == 3) {
                game.winnerPlayer = game.currentPlayer;
                game.status = GameStatus.Finished;
                Message("Player won!");
                break;
            }
        }
        // we don't have winner if it is a fifth move
        if (game.moves[game.currentPlayer].length == 5)
            game.status = GameStatus.Finished;
    }

    function payReward(uint gameId) private {
        Game storage game = games[gameId];
        require(game.status == GameStatus.Finished);

        // the winnerPlayer takes greens, otherwise it is DRAW
        if (game.winnerPlayer != 0) {
            game.winnerPlayer.transfer(game.betValue * 2);
            RewardPayed(gameId, game.winnerPlayer, game.betValue * 2);
        } else {
            game.player1.transfer(game.betValue);
            RewardPayed(gameId, game.player1, game.betValue);
            game.player2.transfer(game.betValue);
            RewardPayed(gameId, game.player2, game.betValue);
        }
    }
}
