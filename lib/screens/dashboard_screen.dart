import 'dart:async';
import 'package:flutter/material';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _timerSeconds = 1500; // 25 Minutes default
  Timer? _timer;
  bool _isRunning = false;
  final List<String> _subjects = ['Math', 'Physics', 'Coding', 'Chemistry'];
  String _selectedSubject = 'Math';
  final Map<String, int> _studyLog = {'Math': 0, 'Physics': 0, 'Coding': 0, 'Chemistry': 0};

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
    } else {
      setState(() => _isRunning = true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_timerSeconds > 0) {
          setState(() => _timerSeconds--);
        } else {
          _timer?.cancel();
          setState(() {
            _isRunning = false;
            _timerSeconds = 1500;
            _studyLog[_selectedSubject] = (_studyLog[_selectedSubject] ?? 0) + 25;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Great job! 25 mins added to $_selectedSubject! 🎉')),
          );
        }
      });
    }
  }

  String _formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('🎯 Study Tracker Pro', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pomodoro Widget
            Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                children: [
                  DropdownButton<String>(
                    value: _selectedSubject,
                    dropdownColor: const Color(0xFF2C2C2C),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    items: _subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedSubject = val!),
                  ),
                  const SizedBox(height: 10),
                  Text(_formatTime(_timerSeconds), style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold, color: Colors.cyanAccent), textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _toggleTimer,
                    style: ElevatedButton.styleFrom(backgroundColor: _isRunning ? Colors.redAccent : Colors.cyanAccent, foregroundColor: Colors.black),
                    child: Text(_isRunning ? 'Pause Focus Session' : 'Start 25 Min Focus'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Your Progress Tracker', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            // Progress Log List
            Expanded(
              child: ListView(_subjects.map((sub) {
                int mins = _studyLog[sub] ?? 0;
                return Card(
                  color: const Color(0xFF1E1E1E),
                  child: ListTile(
                    leading: const Icon(Icons.book, color: Colors.cyanAccent),
                    title: Text(sub, style: const TextStyle(color: Colors.white)),
                    trailing: Text('$mins mins logged', style: const TextStyle(color: Colors.grey)),
                  ),
                );
              }).toList()),
            )
          ],
        ),
      ),
    );
  }
}
