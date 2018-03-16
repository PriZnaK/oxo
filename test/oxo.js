const Reverter = require('./helpers/reverter');
const Asserts = require('./helpers/asserts');
const OXO = artifacts.require('./OXO.sol');

contract('OXO Game', function (accounts) {
  const reverter = new Reverter(web3);
  afterEach('revert', reverter.revert);

  const asserts = Asserts(assert);
  const Player1 = accounts[1];
  const Player2 = accounts[2];
  let oxoGame;

  before('setup', () => {
    return OXO.deployed()
      .then(instance => (oxoGame = instance))
      .then(reverter.snapshot);
  });

  it('should allow to create game', async () => {
    await oxoGame.createGame({from: Player1, value: 100});
    var result = await oxoGame.createGame.call({from: Player1, value: 100});
    assert.equal(result, 1);
  });

  it('should allow to join game', async () => {
    await oxoGame.createGame({from: Player1, value: 100});
    assert.isTrue(await oxoGame.joinGame.call(0, {from: Player2, value: 100}));
  });

  it('should not allow to join yourself', async () => {
    await oxoGame.createGame({from: Player1, value: 100});
    await asserts.throws(oxoGame.joinGame.call(0, {from: Player1, value: 100}));
  });

  it('should not allow to join with differend bet size', async () => {
    await oxoGame.createGame({from: Player1, value: 100});
    await asserts.throws(oxoGame.joinGame.call(0, {from: Player1, value: 50}));
  });

  it('should allow to join only game with NEW status', async () => {
    await oxoGame.createGame({from: Player1, value: 100});
    await oxoGame.joinGame(0, {from: Player2, value: 100});
    await asserts.throws(oxoGame.joinGame.call(0, {from: Player2, value: 100}));
  });

  it('should allow to make move', async () => {
    await oxoGame.createGame({from: Player1, value: 100});
    await oxoGame.joinGame(0, {from: Player2, value: 100});
    asserts.isTrue(await oxoGame.makeMove.call(0, 1, {from: Player1}));
  });

  it('should not allow to make move second time', async () => {
    await oxoGame.createGame({from: Player1, value: 100});
    await oxoGame.joinGame(0, {from: Player2, value: 100});
    await oxoGame.makeMove(0, 1, {from: Player1});
    await asserts.throws(oxoGame.makeMove.call(0, 1, {from: Player1}));
  });

  it('should not allow to make move on same fieldNumber', async () => {
    await oxoGame.createGame({from: Player1, value: 100});
    await oxoGame.joinGame(0, {from: Player2, value: 100});
    await oxoGame.makeMove(0, 1, {from: Player1});
    await oxoGame.makeMove(0, 2, {from: Player2});
    assert.isFalse(await oxoGame.makeMove.call(0, 1, {from: Player1}));
  });

  it('should not allow to cancel before timeout', async () => {
    await oxoGame.createGame({from: Player1, value: 100});
    await oxoGame.joinGame(0, {from: Player2, value: 100});
    await oxoGame.makeMove(0, 1, {from: Player1});
    await oxoGame.makeMove(0, 2, {from: Player2});
    await asserts.throws(oxoGame.cancelGame.call(0, {from: Player1}));
  });

  // test with arbitrary data
  let testData = require('./oxotestdata.json');
  it('should be only 3 draw games in arbitrary data', async () => {
    let drawsCount = 0;
    for (var i = 0; i < testData.length; i++) {
      var moves = testData[i];
      await oxoGame.createGame({from: Player1, value: 100});
      await oxoGame.joinGame(i, {from: Player2, value: 100});
      for (var g = 0; g < moves.length; g++) {
        let fieldNumber = moves[g][0] * 3 + moves[g][1] + 1;
        if (g % 2 === 0) {
          await oxoGame.makeMove(i, fieldNumber, {from: Player1});
        } else {
          await oxoGame.makeMove(i, fieldNumber, {from: Player2});
        }
      }
      let gameStatus = await oxoGame.gameStatus.call(i);
      if (gameStatus[0] - 2 === 0 && gameStatus[2] === '0x0000000000000000000000000000000000000000') {
        drawsCount++;
      }
    }
    assert.equal(drawsCount, 3);
  });

  it('more tests are comming...');
});
