import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class InstructionSection extends StatefulWidget {
  final DocumentSnapshot project;

  const InstructionSection({Key? key, required this.project}) : super(key: key);

  @override
  _InstructionSectionState createState() => _InstructionSectionState();
}

class _InstructionSectionState extends State<InstructionSection> {
  List<bool> _stepCompletionList = [];

  @override
  void initState() {
    super.initState();
    _initializeStepCompletionList();
  }

  void _initializeStepCompletionList() {
    // Initialize _stepCompletionList with false for each step
    final instructions = widget.project['instructions'] as String;
    final steps = instructions.split('\n');
    final stepCount = steps.length;
    _stepCompletionList = List.generate(stepCount, (index) => false);
  }

  void _toggleStepCompletion(int index) {
    setState(() {
      _stepCompletionList[index] = !_stepCompletionList[index];
    });
  }

  double _calculateProgress() {
    final completedCount = _stepCompletionList.where((completed) => completed).length;
    final totalCount = _stepCompletionList.length;
    return totalCount == 0 ? 0 : completedCount / totalCount;
  }

  @override
  Widget build(BuildContext context) {
    final instructions = widget.project['instructions'] as String;
    final steps = instructions.split('\n');

    print('Instructions: $instructions'); 

    return Padding(
      padding: EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Instructions:",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          ListView.builder(
            shrinkWrap: true,
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = steps[index];
              final isCompleted = _stepCompletionList[index];

              return ListTile(
                title: Text(step),
                trailing: IconButton(
                  icon: Icon(isCompleted ? Icons.check_circle : Icons.radio_button_unchecked),
                  onPressed: () => _toggleStepCompletion(index),
                ),
              );
            },
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: _calculateProgress(),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 5),
          Text(
            "Progress: ${(_calculateProgress() * 100).toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
