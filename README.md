# OXO Game (Solidity)

### Author
Sergii Mas <kirajax@gmail.com>

### Features
* you can create and play multiple games at a time
* when game finishes, players receive rewards automaticaly
* if your opponent doesn't join the game or doesn't make moves during 1 hour, you can cancel the game with cancelGame() and your bet will be returned

### HowTo
* create game with createGame() and send some coins which will be a bet for this game
* you receive 'gameId' and give it to your opponent and the bet value as well
* your opponent can join the game using this 'gameId' and sending exact same bet value
* make your move selecting a field number from 1 to 9:
   [1|2|3]
   [4|5|6]
   [7|8|9]
* check status of the game and opponent's moves using gameStatus()
* glhf ;)