import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';

void main() {
  // Set the orientation to landscape
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
    
  ]);

  runApp(PallanguzhiApp());
}

class PallanguzhiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pallanguzhi',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: PallanguzhiBoard(),
    
    );
  }
}

class PallanguzhiBoard extends StatefulWidget {
  @override
  _PallanguzhiBoardState createState() => _PallanguzhiBoardState();
}

class _PallanguzhiBoardState extends State<PallanguzhiBoard> {
  late List<int> pits;
  int player1Score = 0;
  int player2Score = 0;
  bool player1Turn = true;
  bool gameStarted = false;
  bool gameOver = false;
  Random random = Random();
  int? highlightedPit; // Used for highlighting pits
  Color defaultPitColor = const Color.fromARGB(255, 161, 118, 118); // Brown
  Color emptyPitColor = Colors.red; // Red only during distribution
  Color activePitColor = Colors.green; // Green for active pits

  @override
  void initState() {
    super.initState();
    pits = List.filled(14, 5); // Initialize the pits with 5 coins each
    tossCoin();
  }

  void tossCoin() {
    setState(() {
      player1Turn = random.nextBool(); // Randomize starting player
      gameStarted = true;
    });
  }

  Future<void> moveCoins(int index) async {
    if (!gameStarted ||
        pits[index] == 0 ||
        (player1Turn && index >= 7) ||
        (!player1Turn && index < 7) ||
        gameOver) {
      return; // Invalid move
    }

    int coins = pits[index];
    setState(() {
      pits[index] = 0; // Empty the selected pit
      highlightedPit = index; // Highlight the pit being emptied
    });

    await Future.delayed(Duration(milliseconds: 300)); // Initial delay for pit hover

    int currentIndex = index;

    while (coins > 0) {
      currentIndex = (currentIndex + 1) % 14;

      // Set hover color for the pit where the coin is dropped
      setState(() {
        highlightedPit = currentIndex; // Highlight the next pit (green)
        pits[currentIndex]++;
      });

      await Future.delayed(Duration(milliseconds: 500)); // Delay between coin movements
      coins--;
    }

    setState(() {
      highlightedPit = null; // Reset highlight after movement
    });

    handleNextPit(currentIndex);
    checkGameOver();
  }

  Future<void> handleNextPit(int currentIndex) async {
    int nextIndex = (currentIndex + 1) % 14;

    while (pits[nextIndex] > 0) {
      int coins = pits[nextIndex];
      setState(() {
        pits[nextIndex] = 0; // Take coins from the next pit
        highlightedPit = nextIndex; // Highlight the pit being emptied (red)
      });

      await Future.delayed(Duration(milliseconds: 300)); // Delay for pit hover

      currentIndex = nextIndex; // Update current index to the next pit

      while (coins > 0) {
        currentIndex = (currentIndex + 1) % 14;
        setState(() {
          highlightedPit = currentIndex; // Highlight the pit receiving the coins (green)
          pits[currentIndex]++;
        });

        await Future.delayed(Duration(milliseconds: 500)); // Delay between coin movements
        coins--;
      }
      nextIndex = (currentIndex + 1) % 14; // Move to the next pit after distributing
    }

    setState(() {
      highlightedPit = null; // Reset highlight after all moves
    });

    int secondNextIndex = (nextIndex + 1) % 14;
    if (pits[nextIndex] == 0 && pits[secondNextIndex] > 0) {
      setState(() {
        int takenCoins = pits[secondNextIndex];
        pits[secondNextIndex] = 0; // Empty the second next pit
        if (player1Turn) {
          player1Score += takenCoins;
        } else {
          player2Score += takenCoins;
        }
        switchTurn();
      });
    } else {
      switchTurn();
    }
  }

  void switchTurn() {
    setState(() {
      player1Turn = !player1Turn;
    });
  }

  void checkGameOver() {
    bool player1PitsEmpty = pits.sublist(0, 7).every((pit) => pit == 0);
    bool player2PitsEmpty = pits.sublist(7, 14).every((pit) => pit == 0);

    if (player1PitsEmpty || player2PitsEmpty) {
      setState(() {
        gameOver = true;
      });
      showGameOverDialog();
    }
  }

  void showGameOverDialog() {
    String winnerMessage;
    if (player1Score > player2Score) {
      winnerMessage = 'Player 1 Wins!';
    } else if (player2Score > player1Score) {
      winnerMessage = 'Player 2 Wins!';
    } else {
      winnerMessage = 'It\'s a tie!';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Game Over', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(winnerMessage, style: TextStyle(fontWeight: FontWeight.bold)),
          actions: <Widget>[
            TextButton(
              child: Text('Restart', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
                resetGame();
              },
            ),
          ],
        );
      },
    );
  }

  void resetGame() {
    setState(() {
      pits = List.filled(14, 5); // Reset the pits with 5 coins each
      player1Score = 0; // Reset Player 1 score
      player2Score = 0; // Reset Player 2 score
      gameOver = false;
      tossCoin();
    });
  }
  
   void showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Instructions', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(
            'Pallanguzhi is a two-player game played on a board with pits and seeds. '
            'Players take turns to move seeds from one pit to another. The goal is to capture '
            'the most seeds. The game ends when all seeds are distributed. The player with '
            'the most seeds wins!',
            style: TextStyle(fontSize: 16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pallanguzhi'),
        actions: [
      /*  IconButton(
            icon: Icon(Icons.info),
            onPressed: showInstructionsDialog,
            tooltip: 'Instructions',
          ),
      */
          Padding(
            padding: const EdgeInsets.only(right: 50.0),
            child: Row(
              children: [
                Text(
                  'Player 1: $player1Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 30),
                Text(
                  'Player 2: $player2Score',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'assets/background.jpg', // Corrected path
            fit: BoxFit.cover,
            width: screenSize.width,
            height: screenSize.height,
          ),
          IconButton(
            icon: Icon(Icons.info),
            onPressed: showInstructionsDialog,
            tooltip: 'Instructions',
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  player1Turn ? "Player 1's Turn" : "Player 2's Turn",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color.fromARGB(255, 5, 0, 0)),
                ),
                SizedBox(height: 20),
                // Centered pits
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Top row: Player 2's pits (right to left, Pits 8 to 14)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(7, (index) {
                          return buildPit(13 - index); // Pits 8 to 14
                        }),
                      ),
                      SizedBox(height: 20),
                      // Bottom row: Player 1's pits (left to right, Pits 1 to 7)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(7, (index) {
                          return buildPit(index); // Pits 1 to 7
                        }),
                      ),
                    ],
                  ),
                ),
                // Removed Restart button from the main display
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Exit the app
                        SystemNavigator.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red, // Button color
                      ),
                      child: Text('Exit', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildPit(int index) {
    Color pitColor = defaultPitColor;
    if (highlightedPit == index) {
      pitColor = (pits[index] > 0) ? activePitColor : emptyPitColor;
    }

    return GestureDetector(
      onTap: () => moveCoins(index),
      child: Container(
        width: 100, // Adjust width for circular shape
        height: 100, // Adjust height for circular shape
        margin: const EdgeInsets.symmetric(horizontal: 10.0), // Adjusted margin for spacing
        decoration: BoxDecoration(
          color: pitColor,
          shape: BoxShape.circle, // Change to circular shape
          border: Border.all(color: Colors.black, width: 2), // Pit border
        ),
        child: Center(
          child: Text(
            '${pits[index]}',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
